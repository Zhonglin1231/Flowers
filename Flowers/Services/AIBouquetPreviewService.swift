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
        apiKey: String,
        modelName: String
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
        
        let referencePreparation = await prepareReferenceImages(from: chosenSelections)
        let prompt = buildPrompt(requirement: requirement, selections: chosenSelections)
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
    
    private func buildPrompt(requirement: String, selections: [AIBouquetSelection]) -> String {
        let selectedSummary = selections.map {
            "\($0.flower.name) x\($0.quantity)"
        }
        .joined(separator: "、")
        
        let userRequirement = requirement.trimmingCharacters(in: .whitespacesAndNewlines)
        let requirementText = userRequirement.isEmpty ? "请生成一束高级感、写实风格的手持花束预览图" : userRequirement
        
        return """
        请生成一张写实、高级感、适合花店下单前预览的花束效果图。用户需求：\(requirementText)。\
        花束中优先体现这些花材：\(selectedSummary)。\
        如果提供了参考图，请尽量保留参考花材的真实花型、颜色和质感；整体构图为单束花束正面展示，包装完整，花材层次分明，光线自然，画面干净，不要出现人物，不要出现多束花。
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
    
    private func uniqueReferenceImages(from selections: [AIBouquetSelection]) -> [URL] {
        var seen = Set<String>()
        var urls: [URL] = []
        
        for selection in selections {
            guard let url = selection.flower.imageURL else { continue }
            if seen.insert(url.absoluteString).inserted {
                urls.append(url)
            }
        }
        
        return urls
    }
    
    private func prepareReferenceImages(from selections: [AIBouquetSelection]) async -> (payloads: [String], sourceURLs: [URL]) {
        let candidateURLs = Array(uniqueReferenceImages(from: selections).prefix(4))
        var payloads: [String] = []
        var sourceURLs: [URL] = []
        
        for url in candidateURLs {
            guard let encodedImage = await downloadAndEncodeImage(from: url) else {
                continue
            }
            payloads.append(encodedImage)
            sourceURLs.append(url)
        }
        
        return (payloads, sourceURLs)
    }
    
    private func downloadAndEncodeImage(from url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                return nil
            }
            
            let mimeType = (httpResponse.mimeType ?? "").lowercased()
            if !mimeType.isEmpty, !mimeType.hasPrefix("image/") {
                return nil
            }
            
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            let jpegData = image.jpegData(compressionQuality: 0.82)
                ?? image.jpegData(compressionQuality: 0.65)
                ?? data
            
            return "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
        } catch {
            return nil
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
    let size: String = "2K"
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
    case invalidAPIKeyFormat(String)
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "请输入 ARK API Key 后再生成预览。"
        case .missingFlowers:
            return "请至少选择一款花材后再生成预览。"
        case .invalidAPIKeyFormat(let message):
            return message
        case .invalidResponse:
            return "图片服务返回了无法识别的结果。"
        case .serverError(let message):
            return "图片服务调用失败：\(message)"
        }
    }
}
