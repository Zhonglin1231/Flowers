//
//  AIPreviewModels.swift
//  Flowers
//
//  Created by Codex on 2026/3/14.
//

import Foundation

struct AIBouquetSelection: Identifiable {
    let flower: Flower
    var quantity: Int
    let score: Double
    let reasons: [String]
    var isSelected: Bool
    
    var id: String { flower.id }
    var estimatedSubtotal: Double { Double(quantity) * flower.price }
}

struct AIBouquetSearchResult {
    let summary: String
    let notes: [String]
    let selections: [AIBouquetSelection]
}

struct AIGeneratedPreview {
    let imageURL: URL
    let prompt: String
    let referenceImages: [URL]
    let usedImageToImage: Bool
    let modelName: String
}
