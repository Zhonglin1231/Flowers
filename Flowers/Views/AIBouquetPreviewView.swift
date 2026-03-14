//
//  AIBouquetPreviewView.swift
//  Flowers
//
//  Created by Codex on 2026/3/14.
//

import SwiftUI

struct AIBouquetPreviewView: View {
    @ObservedObject var bouquetViewModel: BouquetViewModel
    @Binding var isPresented: Bool
    
    @StateObject private var aiViewModel = AIBouquetPreviewViewModel()
    
    private var flowersWithImagesCount: Int {
        bouquetViewModel.availableFlowers.filter { $0.imageURL != nil }.count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    sourceCard
                    promptCard
                    searchSummaryCard
                    
                    if !aiViewModel.selections.isEmpty {
                        recommendationSection
                        actionSection
                    }
                    
                    previewSection
                }
                .padding()
            }
            .background(Color(red: 0.98, green: 0.96, blue: 0.94).ignoresSafeArea())
            .navigationTitle("AI 预览实验室")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if aiViewModel.selectedCount > 0 {
                        Button("同步到花束") {
                            bouquetViewModel.applyAISelection(aiViewModel.selections, requirement: aiViewModel.requirement)
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据库快照")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("当前已载入 \(bouquetViewModel.availableFlowers.count) 款花材")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("其中 \(flowersWithImagesCount) 款带参考图，可直接参与图生图生成；其余花材会继续参与智能检索，但生成时会退回文生图。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                metricChip(title: "参考图", value: "\(flowersWithImagesCount)")
                metricChip(title: "已选花材", value: "\(aiViewModel.selectedCount)")
                metricChip(title: "估算成本", value: "¥\(String(format: "%.1f", aiViewModel.estimatedTotal))")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.27, blue: 0.21),
                    Color(red: 0.36, green: 0.49, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private func metricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.75))
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("输入花束需求")
                .font(.headline)
            
            ZStack(alignment: .topLeading) {
                if aiViewModel.requirement.isEmpty {
                    Text("例如：送毕业的，想要明亮一点，有一点高级感，主色偏奶油白和浅粉")
                        .foregroundColor(.secondary)
                        .padding(.top, 12)
                        .padding(.leading, 6)
                }
                
                TextEditor(text: $aiViewModel.requirement)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .background(Color.clear)
            }
            .padding(8)
            .background(Color(red: 0.96, green: 0.93, blue: 0.91))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            VStack(alignment: .leading, spacing: 10) {
                SecureField("ARK API Key（只填 key 本身，别带 Bearer）", text: $aiViewModel.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                TextField("模型名", text: $aiViewModel.modelName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text("支持直接粘贴 key 本身，也支持整行 `Bearer ...` 或 `Authorization: Bearer ...`；界面会自动清洗。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button {
                aiViewModel.resetOutput()
                aiViewModel.search(flowers: bouquetViewModel.availableFlowers)
            } label: {
                HStack {
                    if aiViewModel.isSearching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text("智能搜索数据库")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.black)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(bouquetViewModel.availableFlowers.isEmpty || aiViewModel.isSearching)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var searchSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("检索结果")
                .font(.headline)
            Text(aiViewModel.searchSummary)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            if !aiViewModel.searchNotes.isEmpty {
                ForEach(aiViewModel.searchNotes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .padding(.top, 5)
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let errorMessage = aiViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("推荐花材")
                    .font(.headline)
                Spacer()
                Text("先确认，再生成预览")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(aiViewModel.selections) { selection in
                AIBouquetSelectionCard(
                    selection: selection,
                    onToggle: {
                        aiViewModel.resetOutput()
                        aiViewModel.toggleSelection(for: selection.id)
                    },
                    onQuantityChange: { quantity in
                        aiViewModel.resetOutput()
                        aiViewModel.setQuantity(for: selection.id, quantity: quantity)
                    }
                )
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await aiViewModel.generatePreview()
                }
            } label: {
                HStack {
                    if aiViewModel.isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "photo.artframe")
                    }
                    Text(aiViewModel.isGenerating ? "正在生成预览..." : "可视化")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.81, green: 0.57, blue: 0.47))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(aiViewModel.selectedCount == 0 || aiViewModel.isGenerating)
            
            Button {
                bouquetViewModel.applyAISelection(aiViewModel.selections, requirement: aiViewModel.requirement)
            } label: {
                Text("先同步到当前花束继续微调")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            }
            .disabled(aiViewModel.selectedCount == 0)
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("生成结果")
                .font(.headline)
            
            if let preview = aiViewModel.generatedPreview {
                VStack(alignment: .leading, spacing: 12) {
                    AsyncImage(url: preview.imageURL) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.black.opacity(0.05))
                                ProgressView()
                            }
                            .frame(height: 320)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        case .failure:
                            placeholderPreview(text: "预览图加载失败，但接口已返回 URL。")
                        @unknown default:
                            placeholderPreview(text: "预览图状态未知。")
                        }
                    }
                    
                    Text(preview.usedImageToImage ? "已使用数据库花图做多参考图生成" : "本次使用文生图生成")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("模型：\(preview.modelName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(preview.prompt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !preview.referenceImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(preview.referenceImages, id: \.absoluteString) { url in
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.black.opacity(0.08))
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.black.opacity(0.08))
                                                .overlay(Image(systemName: "photo"))
                                        @unknown default:
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.black.opacity(0.08))
                                        }
                                    }
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                placeholderPreview(text: "完成花材确认后点击“可视化”，这里会显示 AI 生成的花束预览图。")
            }
        }
    }
    
    private func placeholderPreview(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct AIBouquetSelectionCard: View {
    let selection: AIBouquetSelection
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                flowerImage
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(selection.flower.emoji) \(selection.flower.name)")
                            .font(.headline)
                        Spacer()
                        Button(action: onToggle) {
                            Image(systemName: selection.isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(selection.isSelected ? .green : .secondary)
                        }
                    }
                    
                    Text("\(selection.flower.categoryDisplayName) · ¥\(String(format: "%.1f", selection.flower.price))/\(selection.flower.unitDisplayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let inventoryCode = selection.flower.inventoryCode {
                        Text("库存编码：\(inventoryCode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(selection.reasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Stepper(
                "推荐数量：\(selection.quantity)",
                value: Binding(
                    get: { selection.quantity },
                    set: { onQuantityChange($0) }
                ),
                in: 1...12
            )
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
    @ViewBuilder
    private var flowerImage: some View {
        if let imageURL = selection.flower.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(selection.flower.color.opacity(0.2))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackFlowerImage
                @unknown default:
                    fallbackFlowerImage
                }
            }
            .frame(width: 92, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            fallbackFlowerImage
        }
    }
    
    private var fallbackFlowerImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(selection.flower.color.opacity(0.18))
            Text(selection.flower.emoji)
                .font(.system(size: 42))
        }
        .frame(width: 92, height: 112)
    }
}

#Preview {
    let bouquetViewModel = BouquetViewModel()
    bouquetViewModel.availableFlowers = Flower.sampleFlowers
    
    return AIBouquetPreviewView(
        bouquetViewModel: bouquetViewModel,
        isPresented: .constant(true)
    )
}
