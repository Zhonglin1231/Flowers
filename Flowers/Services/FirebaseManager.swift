//
//  FirebaseManager.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import SwiftUI
import UIKit

// MARK: - Firebase 管理器
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let db: Firestore
    let auth: Auth
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        self.db = Firestore.firestore()
        self.auth = Auth.auth()
        
        // 监听认证状态变化
        authListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
}

// MARK: - Firestore 数据模型（可编码）

/// 花卉数据模型（用于 Firestore）
struct FlowerData: Identifiable {
    let documentID: String?
    let id: String?
    let name: String
    let englishName: String?
    let colorHex: String?
    let color: String?
    let price: Double
    let emoji: String?
    let category: String
    let description: String
    let isAvailable: Bool?
    let stockQuantity: Int?
    let image: String?
    let inventoryCode: String?
    let inventory_code: String?
    let unit: String?
    let season: String?
    
    init?(documentID: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let category = data["category"] as? String else {
            return nil
        }
        
        let priceNumber = data["price"] as? NSNumber
        
        self.documentID = documentID
        self.id = data["id"] as? String
        self.name = name
        self.englishName = data["englishName"] as? String
        self.colorHex = data["colorHex"] as? String
        self.color = data["color"] as? String
        self.price = priceNumber?.doubleValue ?? 0
        self.emoji = data["emoji"] as? String
        self.category = category
        self.description = data["description"] as? String ?? ""
        self.isAvailable = data["isAvailable"] as? Bool
        self.stockQuantity = (data["stockQuantity"] as? NSNumber)?.intValue
        self.image = data["image"] as? String
        self.inventoryCode = data["inventoryCode"] as? String
        self.inventory_code = data["inventory_code"] as? String
        self.unit = data["unit"] as? String
        self.season = data["season"] as? String
    }
    
    var resolvedId: String {
        id ?? documentID ?? UUID().uuidString
    }
    
    var resolvedCategory: FlowerCategory {
        FlowerCategory(databaseValue: category)
    }
    
    var resolvedEmoji: String {
        emoji ?? resolvedCategory.icon
    }
    
    var resolvedColor: Color {
        Color.fromDescriptor(colorHex)
        ?? Color.fromDescriptor(color)
        ?? Color.fallback(for: resolvedCategory)
    }
    
    var resolvedUnit: String {
        let trimmedUnit = unit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedUnit.isEmpty ? "stem" : trimmedUnit
    }
    
    var resolvedInventoryCode: String? {
        let code = inventoryCode ?? inventory_code
        return code?.isEmpty == true ? nil : code
    }
    
    var resolvedSeason: String? {
        guard let season, !season.isEmpty else { return nil }
        return season
    }
    
    func toFlower() -> Flower {
        Flower(
            id: resolvedId,
            name: name,
            englishName: englishName ?? name,
            color: resolvedColor,
            price: price,
            emoji: resolvedEmoji,
            category: resolvedCategory,
            categoryName: category,
            description: description,
            imageURL: URL(string: image ?? ""),
            stockQuantity: stockQuantity,
            inventoryCode: resolvedInventoryCode,
            unit: resolvedUnit,
            season: resolvedSeason,
            colorName: color
        )
    }
}

/// 花束项数据模型
struct BouquetItemData: Codable {
    let flowerId: String
    let flowerName: String
    let flowerEmoji: String
    let flowerPrice: Double
    var quantity: Int
    var positionX: Double
    var positionY: Double
    var scale: Double
    var rotation: Double
}

/// 花束数据模型
struct BouquetData: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var items: [BouquetItemData]
    var wrappingStyle: String
    var ribbonColorHex: String
    var note: String
    let createdAt: Date
    let userId: String?
    var totalPrice: Double
    var imageURL: String? = nil
    var tagline: String? = nil
    var descriptionLines: [String]? = nil
    var longDescription: [String]? = nil
    var isPublished: Bool? = nil
    var isTemplate: Bool? = nil
}

/// 订单数据模型
struct OrderData: Codable, Identifiable {
    @DocumentID var id: String?
    let bouquetId: String
    let bouquetData: BouquetData
    let customerName: String
    let customerPhone: String
    let deliveryAddress: String
    let deliveryDate: Date
    let specialRequests: String
    var status: String
    let createdAt: Date
    let userId: String?
}

// MARK: - Color 扩展
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        let components = UIColor(self).cgColor.components ?? [1, 0.41, 0.71, 1]
        
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        
        switch components.count {
        case 2:
            r = components[0]
            g = components[0]
            b = components[0]
        default:
            r = components.count > 0 ? components[0] : 1
            g = components.count > 1 ? components[1] : 0.41
            b = components.count > 2 ? components[2] : 0.71
        }
        
        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
    
    static func fromDescriptor(_ value: String?) -> Color? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        
        if value.hasPrefix("#"), let hexColor = Color(hex: value) {
            return hexColor
        }
        
        switch value.lowercased() {
        case "red":
            return .red
        case "pink", "blush pink", "blush":
            return .pink
        case "white", "ivory", "cream":
            return .white
        case "purple", "violet", "lilac":
            return .purple
        case "yellow", "gold":
            return .yellow
        case "orange", "coral", "peach", "champagne":
            return Color(red: 1.0, green: 0.73, blue: 0.55)
        case "blue":
            return .blue
        case "green", "sage", "olive":
            return .green
        default:
            return nil
        }
    }
    
    static func fallback(for category: FlowerCategory) -> Color {
        switch category {
        case .rose, .carnation:
            return .pink
        case .tulip, .lavender:
            return .purple
        case .lily, .gypsophila:
            return .white
        case .sunflower:
            return .yellow
        case .hydrangea:
            return .blue
        case .greenery:
            return .green
        case .peony:
            return Color(red: 0.98, green: 0.65, blue: 0.71)
        case .other:
            return .pink
        }
    }
}
