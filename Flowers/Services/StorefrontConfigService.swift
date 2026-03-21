//
//  StorefrontConfigService.swift
//  Flowers
//
//  Created by Codex on 2026/3/21.
//

import Combine
import FirebaseFirestore
import Foundation

struct StorefrontPreviewConfiguration: Equatable {
    let apiKey: String?
    let modelName: String?
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
    
    static let documentPath = "settings/wrapping_options"
    
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
        
        guard let resolvedID,
              let resolvedName,
              let resolvedImageURL else {
            return nil
        }
        
        self.id = resolvedID
        self.name = resolvedName
        self.imageURL = resolvedImageURL
        self.price = resolvedPrice ?? 0
    }
}

final class StorefrontConfigService: ObservableObject {
    private let db = FirebaseManager.shared.db
    private var previewListener: ListenerRegistration?
    private var wrappingListener: ListenerRegistration?
    
    @Published var previewConfiguration: StorefrontPreviewConfiguration?
    @Published var wrappingOptions: [StorefrontWrappingOptionData] = []
    @Published var hasResolvedWrappingOptions = false
    @Published var error: String?
    
    deinit {
        previewListener?.remove()
        wrappingListener?.remove()
    }
    
    func startListening() {
        previewListener?.remove()
        wrappingListener?.remove()
        
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
        
        wrappingListener = db.collection("settings")
            .document("wrapping_options")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.hasResolvedWrappingOptions = true
                
                if let error = error {
                    self?.error = error.localizedDescription
                    self?.wrappingOptions = []
                    return
                }
                
                guard let data = snapshot?.data(),
                      let rawOptions = data["options"] as? [[String: Any]] else {
                    self?.wrappingOptions = []
                    return
                }
                
                self?.wrappingOptions = rawOptions.compactMap { option in
                    StorefrontWrappingOptionData(data: option)
                }
            }
    }
}
