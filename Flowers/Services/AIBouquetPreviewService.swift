//
//  AIBouquetPreviewService.swift
//  Flowers
//
//  Created by Codex on 2026/3/14.
//

import Foundation
import UIKit

struct AIBouquetPreviewService {
    private let session: URLSession = .shared
    
    func search(requirement: String, flowers: [Flower]) -> AIBouquetSearchResult {
        let trimmedRequirement = requirement.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRequirement = normalize(trimmedRequirement)
        let themeMatches = themeRules.filter { rule in
            rule.keywords.contains { normalizedRequirement.contains(normalize($0)) }
        }
        
        let rankedSelections = flowers
            .map { flower in
                buildSelection(for: flower, requirement: trimmedRequirement, normalizedRequirement: normalizedRequirement, themeMatches: themeMatches)
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.flower.price > $1.flower.price
                }
                return $0.score > $1.score
            }
        
        let selections = Array(rankedSelections.prefix(6)).enumerated().map { index, selection in
            AIBouquetSelection(
                flower: selection.flower,
                quantity: selection.quantity,
                score: selection.score,
                reasons: selection.reasons,
                isSelected: index < 4
            )
        }
        
        let notes = themeMatches.map(\.note)
        let summary: String
        if trimmedRequirement.isEmpty {
            summary = "已从数据库里选出一组基础花材，适合你先测试 AI 预览链路。"
        } else if selections.isEmpty {
            summary = "数据库里没有找到明显匹配的花材，建议换一个更具体的描述。"
        } else {
            summary = "已从数据库的 \(flowers.count) 款花材中筛出 \(selections.count) 款更贴近“\(trimmedRequirement)”的候选。"
        }
        
        return AIBouquetSearchResult(summary: summary, notes: notes, selections: selections)
    }
    
    func generatePreview(
        requirement: String,
        selections: [AIBouquetSelection],
        wrappingOption: BouquetWrappingOption?,
        apiKey: String,
        modelName: String,
        requireReferenceImages: Bool = false
    ) async throws -> AIGeneratedPreview {
        let cleanedKey = sanitizeAPIKey(apiKey)
        guard !cleanedKey.isEmpty else {
            throw AIPreviewError.missingAPIKey
        }
        
        if cleanedKey.hasPrefix("AIza") {
            throw AIPreviewError.invalidAPIKeyFormat("你填入的看起来像 Firebase API Key，不是 Ark API Key。")
        }
        
        let chosenSelections = selections.filter(\.isSelected)
        guard !chosenSelections.isEmpty else {
            throw AIPreviewError.missingFlowers
        }

        let missingReferenceFlowers = chosenSelections
            .filter { !$0.flower.hasReferenceImage }
            .map(\.flower.name)
        if requireReferenceImages, !missingReferenceFlowers.isEmpty {
            throw AIPreviewError.missingFlowerReferenceImages(missingReferenceFlowers)
        }
        if requireReferenceImages, wrappingOption?.hasReferenceImage != true {
            throw AIPreviewError.missingWrappingReferenceImage(wrappingOption?.name)
        }
        
        let referencePreparation = await prepareReferenceImages(from: chosenSelections, wrappingOption: wrappingOption)
        if requireReferenceImages, referencePreparation.payloads.count < referencePreparation.expectedCount {
            throw AIPreviewError.referenceImageUnavailable(referencePreparation.failures)
        }
        let prompt = buildPrompt(requirement: requirement, selections: chosenSelections, wrappingOption: wrappingOption)
        let requestBody = ArkImageGenerationRequest(
            model: modelName,
            prompt: prompt,
            image: referencePreparation.payloads.isEmpty ? nil : referencePreparation.payloads
        )
        
        var request = URLRequest(url: URL(string: "https://ark.cn-beijing.volces.com/api/v3/images/generations")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanedKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIPreviewError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "未知错误"
            if serverMessage.localizedCaseInsensitiveContains("API key format is incorrect") {
                throw AIPreviewError.invalidAPIKeyFormat("当前值不是可用的 Ark API Key。请输入方舟控制台创建的 API Key 本体，不要粘贴完整 curl，也不要填 `Authorization:`。")
            }
            throw AIPreviewError.serverError(serverMessage)
        }
        
        let decoded = try JSONDecoder().decode(ArkImageGenerationResponse.self, from: data)
        if let imageURL = decoded.primaryURL {
            return AIGeneratedPreview(
                imageURL: imageURL,
                prompt: prompt,
                referenceImages: referencePreparation.sourceURLs,
                usedImageToImage: !referencePreparation.payloads.isEmpty,
                modelName: modelName
            )
        }
        
        throw AIPreviewError.invalidResponse
    }
    
    private func buildSelection(
        for flower: Flower,
        requirement: String,
        normalizedRequirement: String,
        themeMatches: [ThemeRule]
    ) -> AIBouquetSelection {
        var score = 0.0
        var reasons: [String] = []
        let searchableText = flower.searchableText
        
        let exactTerms = [flower.name, flower.englishName, flower.categoryName]
        for term in exactTerms {
            let normalizedTerm = normalize(term)
            guard !normalizedTerm.isEmpty else { continue }
            if normalizedRequirement.contains(normalizedTerm) {
                score += 28
                reasons.append("命中关键词“\(term)”")
            }
        }
        
        if let colorName = flower.colorName, normalizedRequirement.contains(normalize(colorName)) {
            score += 16
            reasons.append("颜色贴近 \(colorName)")
        }
        
        if let season = flower.season, normalizedRequirement.contains(normalize(season)) {
            score += 8
            reasons.append("季节信息匹配 \(season)")
        }
        
        for token in extractMeaningfulTokens(from: requirement) where searchableText.contains(token) {
            score += 6
            if reasons.count < 3 {
                reasons.append("描述命中“\(token)”")
            }
        }
        
        for theme in themeMatches {
            if theme.preferredCategories.contains(flower.category) {
                score += 18
                reasons.append(theme.note)
            }
            
            if let colorName = flower.colorName,
               theme.preferredColors.contains(where: { normalize(colorName).contains(normalize($0)) }) {
                score += 10
                reasons.append("色调接近 \(colorName)")
            }
        }
        
        if reasons.isEmpty {
            reasons = ["作为基础搭配花材可用于测试预览"]
            score += 1
        }
        
        return AIBouquetSelection(
            flower: flower,
            quantity: suggestedQuantity(for: flower),
            score: score,
            reasons: Array(reasons.prefix(3)),
            isSelected: false
        )
    }
    
    private func suggestedQuantity(for flower: Flower) -> Int {
        switch flower.category {
        case .rose, .tulip, .carnation:
            return 3
        case .peony, .lily, .hydrangea, .sunflower:
            return 2
        case .gypsophila, .greenery, .lavender:
            return 1
        case .other:
            return 2
        }
    }
    
    private func buildPrompt(requirement: String, selections: [AIBouquetSelection], wrappingOption: BouquetWrappingOption?) -> String {
        let selectedSummary = selections.map {
            "\($0.flower.name) x\($0.quantity)"
        }
        .joined(separator: "、")
        let wrappingDescription = wrappingOption?.name
            ?? requirement.trimmingCharacters(in: .whitespacesAndNewlines)
        let wrappingLine = wrappingDescription.isEmpty
            ? ""
            : "包装必须使用参考图对应的\(wrappingDescription)。"
        
        return """
        请生成一张写实、高级感、适合花店下单前预览的花束效果图。\
        花束中必须体现这些实际已选花材：\(selectedSummary)。\
        \(wrappingLine)\
        如果提供了参考图，请严格以参考图里的真实花型、颜色、质感、品种和包装样式为准，不要凭空替换成其他花材或包装；整体构图为单束花束正面展示，包装完整，花材层次分明，光线自然，画面干净，不要出现人物，不要出现多束花。
        """
    }
    
    private func extractMeaningfulTokens(from text: String) -> [String] {
        normalize(text)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 3 }
    }
    
    private func sanitizeAPIKey(_ rawValue: String) -> String {
        let normalized = rawValue
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{200C}", with: "")
            .replacingOccurrences(of: "\u{200D}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let patterns = [
            #"Authorization:\s*Bearer\s+([^\s"']+)"#,
            #"-H\s*"Authorization:\s*Bearer\s+([^\s"']+)""#,
            #"Bearer\s+([^\s"']+)"#,
            #"ARK_API_KEY\s*=\s*["']?([^"'\s]+)"?"#,
            #"([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
               let range = Range(match.range(at: 1), in: trimmed) {
                return String(trimmed[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return trimmed
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func referenceImageCandidates(from selections: [AIBouquetSelection], wrappingOption: BouquetWrappingOption?) -> [ReferenceImageCandidate] {
        var seen = Set<String>()
        var candidates: [ReferenceImageCandidate] = []
        
        for selection in selections {
            guard let source = normalizedReferenceSource(selection.flower.imageURL?.absoluteString),
                  let url = URL(string: source),
                  seen.insert(source).inserted else {
                continue
            }
            candidates.append(
                ReferenceImageCandidate(
                    label: "花材“\(selection.flower.name)”",
                    source: source,
                    url: url
                )
            )
        }
        
        if let wrappingOption,
           let source = normalizedReferenceSource(wrappingOption.imageURL),
           let url = URL(string: source),
           seen.insert(source).inserted {
            candidates.append(
                ReferenceImageCandidate(
                    label: "包装“\(wrappingOption.name)”",
                    source: source,
                    url: url
                )
            )
        }
        
        return candidates
    }
    
    private func normalizedReferenceSource(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private func prepareReferenceImages(from selections: [AIBouquetSelection], wrappingOption: BouquetWrappingOption?) async -> ReferenceImagePreparationResult {
        let candidates = referenceImageCandidates(from: selections, wrappingOption: wrappingOption)
        var payloads: [String] = []
        var sourceURLs: [URL] = []
        var failures: [String] = []
        
        for candidate in candidates {
            switch await loadReferenceImage(from: candidate) {
            case .success(let encodedImage):
                payloads.append(encodedImage)
                sourceURLs.append(candidate.url)
            case .failure(let reason):
                failures.append("\(candidate.label)：\(reason)")
            }
        }
        
        return ReferenceImagePreparationResult(
            payloads: payloads,
            sourceURLs: sourceURLs,
            expectedCount: candidates.count,
            failures: failures
        )
    }
    
    private func loadReferenceImage(from candidate: ReferenceImageCandidate) async -> ReferenceImageLoadResult {
        switch candidate.url.scheme?.lowercased() {
        case "http", "https":
            return await downloadAndEncodeImage(from: candidate.url)
        case "data":
            return decodeDataImage(from: candidate.source)
        case let scheme?:
            return .failure("暂不支持 `\(scheme)` 协议的图片链接。")
        default:
            return .failure("图片链接格式无效。")
        }
    }
    
    private func decodeDataImage(from source: String) -> ReferenceImageLoadResult {
        guard let separatorIndex = source.firstIndex(of: ",") else {
            return .failure("`data:` 图片缺少内容。")
        }
        
        let metadata = String(source[..<separatorIndex]).lowercased()
        let payload = String(source[source.index(after: separatorIndex)...])
        guard metadata.hasPrefix("data:image/") else {
            return .failure("`data:` 链接不是图片。")
        }
        
        let rawData: Data?
        if metadata.contains(";base64") {
            rawData = Data(base64Encoded: payload)
        } else {
            rawData = payload.removingPercentEncoding?.data(using: .utf8)
        }
        
        guard let rawData else {
            return .failure("`data:` 图片内容无法解析。")
        }
        
        guard let image = UIImage(data: rawData) else {
            return .failure("`data:` 链接里的内容不是有效图片。")
        }
        
        let jpegData = image.jpegData(compressionQuality: 0.82)
            ?? image.jpegData(compressionQuality: 0.65)
            ?? rawData
        
        return .success("data:image/jpeg;base64,\(jpegData.base64EncodedString())")
    }
    
    private func downloadAndEncodeImage(from url: URL) async -> ReferenceImageLoadResult {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("未收到有效的 HTTP 响应。")
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                return .failure("下载返回了 HTTP \(httpResponse.statusCode)。")
            }
            
            let mimeType = (httpResponse.mimeType ?? "").lowercased()
            if !mimeType.isEmpty, !mimeType.hasPrefix("image/") {
                return .failure("返回的是 `\(mimeType)`，不是图片。")
            }
            
            guard let image = UIImage(data: data) else {
                return .failure("下载成功了，但内容不是可解码的图片。")
            }
            
            let jpegData = image.jpegData(compressionQuality: 0.82)
                ?? image.jpegData(compressionQuality: 0.65)
                ?? data
            
            return .success("data:image/jpeg;base64,\(jpegData.base64EncodedString())")
        } catch {
            return .failure(error.localizedDescription)
        }
    }
    
    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "[^\\p{L}\\p{N}]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var themeRules: [ThemeRule] {
        [
            ThemeRule(
                keywords: ["浪漫", "表白", "romantic", "anniversary", "约会"],
                preferredCategories: [.rose, .peony, .hydrangea],
                preferredColors: ["pink", "blush", "coral", "red"],
                note: "风格偏浪漫柔和"
            ),
            ThemeRule(
                keywords: ["高级", "优雅", "elegant", "clean", "minimal", "简约"],
                preferredCategories: [.lily, .hydrangea, .rose],
                preferredColors: ["white", "ivory", "cream", "blush"],
                note: "风格偏简洁高级"
            ),
            ThemeRule(
                keywords: ["生日", "毕业", "阳光", "活泼", "celebration", "bright"],
                preferredCategories: [.sunflower, .tulip, .peony],
                preferredColors: ["yellow", "orange", "coral", "pink"],
                note: "风格偏明亮庆祝"
            ),
            ThemeRule(
                keywords: ["婚礼", "wedding", "bridal"],
                preferredCategories: [.rose, .peony, .hydrangea, .lily],
                preferredColors: ["white", "ivory", "pink", "blush"],
                note: "适合婚礼或仪式感花束"
            ),
            ThemeRule(
                keywords: ["疗愈", "宁静", "舒缓", "calm", "lavender", "香气"],
                preferredCategories: [.lavender, .gypsophila, .greenery],
                preferredColors: ["lilac", "white", "green"],
                note: "风格偏疗愈自然"
            )
        ]
    }
}

private struct ReferenceImageCandidate {
    let label: String
    let source: String
    let url: URL
}

private struct ReferenceImagePreparationResult {
    let payloads: [String]
    let sourceURLs: [URL]
    let expectedCount: Int
    let failures: [String]
}

private enum ReferenceImageLoadResult {
    case success(String)
    case failure(String)
}

private struct ThemeRule {
    let keywords: [String]
    let preferredCategories: [FlowerCategory]
    let preferredColors: [String]
    let note: String
}

private struct ArkImageGenerationRequest: Encodable {
    let model: String
    let prompt: String
    let image: [String]?
    let sequentialImageGeneration: String = "disabled"
    let responseFormat: String = "url"
    let size: String = "1280x720"
    let stream: Bool = false
    let watermark: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case image
        case size
        case stream
        case watermark
        case sequentialImageGeneration = "sequential_image_generation"
        case responseFormat = "response_format"
    }
}

private struct ArkImageGenerationResponse: Decodable {
    struct ImageResource: Decodable {
        let url: URL?
    }
    
    let data: [ImageResource]?
    let images: [ImageResource]?
    
    var primaryURL: URL? {
        data?.first?.url ?? images?.first?.url
    }
}

enum AIPreviewError: LocalizedError {
    case missingAPIKey
    case missingFlowers
    case missingFlowerReferenceImages([String])
    case missingWrappingReferenceImage(String?)
    case referenceImageUnavailable([String])
    case invalidAPIKeyFormat(String)
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "请输入 ARK API Key 后再生成预览。"
        case .missingFlowers:
            return "请至少选择一款花材后再生成预览。"
        case .missingFlowerReferenceImages(let flowerNames):
            return "这些已选花材还没有参考图，当前不能生成真实预览：\(flowerNames.joined(separator: "、"))。"
        case .missingWrappingReferenceImage(let wrappingName):
            if let wrappingName, !wrappingName.isEmpty {
                return "包装“\(wrappingName)”还没有 Firestore 参考图，当前不能生成真实预览。"
            }
            return "当前所选包装没有 Firestore 参考图，不能生成真实预览。"
        case .referenceImageUnavailable(let failures):
            if failures.isEmpty {
                return "当前无法拿到 Firestore 里的花材或包装参考图，请检查图片链接后再试。"
            }
            return "这些参考图当前不可用：\(failures.joined(separator: "；"))"
        case .invalidAPIKeyFormat(let message):
            return message
        case .invalidResponse:
            return "图片服务返回了无法识别的结果。"
        case .serverError(let message):
            return "图片服务调用失败：\(message)"
        }
    }
}
