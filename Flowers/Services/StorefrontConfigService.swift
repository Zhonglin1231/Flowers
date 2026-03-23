//
//  StorefrontConfigService.swift
//  Flowers
//
//  Created by Codex on 2026/3/21.
//

import Combine
import FirebaseFirestore
import Foundation

struct InventoryRecordData: Identifiable, Equatable {
    let id: String
    let stock: Int

    init?(documentID: String, data: [String: Any]) {
        guard let stockNumber = data["stock"] as? NSNumber else {
            return nil
        }

        self.id = documentID
        self.stock = stockNumber.intValue
    }
}

struct StorefrontPreviewConfiguration: Equatable {
    let apiKey: String?
    let modelName: String?
    let assistantApiKey: String?
    let assistantModelName: String?
    let isEnabled: Bool
    
    static let documentPath = "settings/ai_preview"
    
    init(data: [String: Any]) {
        self.apiKey = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["apiKey"],
            data["arkApiKey"],
            data["previewApiKey"]
        )
        self.modelName = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["modelName"],
            data["imageModel"],
            data["arkImageModel"]
        )
        self.assistantApiKey = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["assistantApiKey"],
            data["chatApiKey"],
            data["textApiKey"],
            data["apiKey"],
            data["arkApiKey"],
            data["previewApiKey"]
        )
        self.assistantModelName = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["assistantModelName"],
            data["chatModel"],
            data["textModel"],
            data["llmModel"]
        )
        self.isEnabled = (data["isEnabled"] as? Bool) ?? true
    }
    
    static func firstNonEmptyString(_ candidates: Any?...) -> String? {
        for candidate in candidates {
            guard let value = candidate as? String else { continue }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }
}

struct StorefrontWrappingOptionData: Identifiable, Equatable {
    let id: String
    let name: String
    let imageURL: String
    let price: Double
    let stockQuantity: Int?
    let inventoryCode: String?
    
    static let collectionPath = "wrapping_options"

    init?(data: [String: Any]) {
        let resolvedID = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["id"],
            data["code"]
        )
        let resolvedName = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["name"],
            data["title"]
        )
        let resolvedImageURL = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["imageURL"],
            data["image"],
            data["referenceImageURL"]
        )
        let resolvedPrice = (data["price"] as? NSNumber)?.doubleValue
        let resolvedStockQuantity = (data["stockQuantity"] as? NSNumber)?.intValue
        let resolvedInventoryCode = StorefrontPreviewConfiguration.firstNonEmptyString(
            data["inventoryCode"],
            data["inventory_code"],
            data["code"],
            data["id"]
        )
        
        guard let resolvedID,
              let resolvedName,
              let resolvedImageURL else {
            return nil
        }
        
        self.id = resolvedID
        self.name = resolvedName
        self.imageURL = resolvedImageURL
        self.price = resolvedPrice ?? 0
        self.stockQuantity = resolvedStockQuantity
        self.inventoryCode = resolvedInventoryCode
    }
}

final class StorefrontConfigService: ObservableObject {
    private let db = FirebaseManager.shared.db
    private var previewListener: ListenerRegistration?
    private var wrappingListener: ListenerRegistration?
    private var inventoryListener: ListenerRegistration?
    
    @Published var previewConfiguration: StorefrontPreviewConfiguration?
    @Published var wrappingOptions: [StorefrontWrappingOptionData] = []
    @Published var inventoryStocksByCode: [String: Int] = [:]
    @Published var hasResolvedInventory = false
    @Published var hasResolvedWrappingOptions = false
    @Published var error: String?
    
    deinit {
        previewListener?.remove()
        wrappingListener?.remove()
        inventoryListener?.remove()
    }
    
    func startListening() {
        previewListener?.remove()
        wrappingListener?.remove()
        inventoryListener?.remove()
        
        previewListener = db.collection("settings")
            .document("ai_preview")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let data = snapshot?.data(), !data.isEmpty else {
                    self?.previewConfiguration = nil
                    return
                }
                
                self?.previewConfiguration = StorefrontPreviewConfiguration(data: data)
            }
        
        wrappingListener = db.collection("wrapping_options")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.hasResolvedWrappingOptions = true
                
                if let error = error {
                    self?.error = error.localizedDescription
                    self?.wrappingOptions = []
                    return
                }
                
                let wrappingOptions: [StorefrontWrappingOptionData] = snapshot?.documents.compactMap { document in
                    var payload = document.data()
                    payload["id"] = payload["id"] ?? document.documentID
                    return StorefrontWrappingOptionData(data: payload)
                } ?? []
                
                self?.wrappingOptions = wrappingOptions.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            }

        inventoryListener = db.collection("inventory")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.hasResolvedInventory = true

                if let error = error {
                    self?.error = error.localizedDescription
                    self?.inventoryStocksByCode = [:]
                    return
                }

                let inventoryRecords: [InventoryRecordData] = snapshot?.documents.compactMap { document in
                    InventoryRecordData(documentID: document.documentID, data: document.data())
                } ?? []

                self?.inventoryStocksByCode = Dictionary(
                    uniqueKeysWithValues: inventoryRecords.map { ($0.id, $0.stock) }
                )
            }
    }
}
