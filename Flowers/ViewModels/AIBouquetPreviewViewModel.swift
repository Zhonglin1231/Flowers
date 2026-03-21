//
//  AIBouquetPreviewViewModel.swift
//  Flowers
//
//  Created by Codex on 2026/3/14.
//

import Combine
import Foundation

@MainActor
final class AIBouquetPreviewViewModel: ObservableObject {
    @Published var requirement = ""
    @Published var apiKey = ProcessInfo.processInfo.environment["ARK_API_KEY"] ?? ""
    @Published var modelName = ProcessInfo.processInfo.environment["ARK_IMAGE_MODEL"] ?? "doubao-seedream-5-0-260128"
    @Published var searchSummary = "输入花束需求后，先做一次数据库智能检索。"
    @Published var searchNotes: [String] = []
    @Published var selections: [AIBouquetSelection] = []
    @Published var generatedPreview: AIGeneratedPreview?
    @Published var isSearching = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private let service = AIBouquetPreviewService()
    
    var selectedSelections: [AIBouquetSelection] {
        selections.filter(\.isSelected)
    }
    
    var selectedCount: Int {
        selectedSelections.count
    }
    
    var estimatedTotal: Double {
        selectedSelections.reduce(0) { $0 + $1.estimatedSubtotal }
    }
    
    func search(flowers: [Flower]) {
        errorMessage = nil
        generatedPreview = nil
        isSearching = true
        
        let result = service.search(requirement: requirement, flowers: flowers)
        searchSummary = result.summary
        searchNotes = result.notes
        selections = result.selections
        isSearching = false
    }
    
    func toggleSelection(for selectionId: String) {
        guard let index = selections.firstIndex(where: { $0.id == selectionId }) else { return }
        selections[index].isSelected.toggle()
    }
    
    func setQuantity(for selectionId: String, quantity: Int) {
        guard let index = selections.firstIndex(where: { $0.id == selectionId }) else { return }
        selections[index].quantity = max(1, quantity)
    }
    
    func generatePreview(requireReferenceImages: Bool = false) async {
        errorMessage = nil
        isGenerating = true
        
        do {
            generatedPreview = try await service.generatePreview(
                requirement: requirement,
                selections: selections,
                wrappingOption: nil,
                apiKey: apiKey,
                modelName: modelName,
                requireReferenceImages: requireReferenceImages
            )
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        
        isGenerating = false
    }
    
    func resetOutput() {
        generatedPreview = nil
        errorMessage = nil
    }
}
