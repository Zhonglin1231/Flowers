//
//  FlowerModel.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import Foundation
import SwiftUI

// MARK: - 花卉类型
struct Flower: Identifiable, Equatable {
    var id: String = UUID().uuidString
    let name: String
    let englishName: String
    let color: Color
    let price: Double
    let emoji: String
    let category: FlowerCategory
    let categoryName: String
    let description: String
    let imageURL: URL?
    let inventoryCode: String?
    let unit: String
    let season: String?
    let colorName: String?
    
    var categoryDisplayName: String {
        category == .other ? categoryName : category.displayName
    }
    
    var unitDisplayName: String {
        switch unit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "stem":
            return "枝"
        case "bunch":
            return "束"
        case "bundle":
            return "把"
        default:
            return unit.isEmpty ? "枝" : unit
        }
    }
    
    var searchableText: String {
        [
            name,
            englishName,
            categoryName,
            category.displayName,
            description,
            season ?? "",
            colorName ?? "",
            inventoryCode ?? ""
        ]
        .joined(separator: " ")
        .lowercased()
    }
    
    static func == (lhs: Flower, rhs: Flower) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 花卉分类
enum FlowerCategory: String, CaseIterable {
    case rose
    case tulip
    case lily
    case carnation
    case sunflower
    case hydrangea
    case gypsophila
    case greenery
    case peony
    case lavender
    case other
    
    init(databaseValue: String) {
        let normalized = databaseValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
        
        switch normalized {
        case "玫瑰", "rose", "roses":
            self = .rose
        case "郁金香", "tulip", "tulips":
            self = .tulip
        case "百合", "lily", "lilies":
            self = .lily
        case "康乃馨", "carnation", "carnations":
            self = .carnation
        case "向日葵", "sunflower", "sunflowers":
            self = .sunflower
        case "绣球花", "hydrangea", "hydrangeas":
            self = .hydrangea
        case "满天星", "gypsophila", "baby's breath", "babys breath":
            self = .gypsophila
        case "配叶", "greenery", "foliage", "filler":
            self = .greenery
        case "芍药", "牡丹", "peony", "peonies":
            self = .peony
        case "薰衣草", "lavender":
            self = .lavender
        default:
            self = .other
        }
    }
    
    var displayName: String {
        switch self {
        case .rose: return "玫瑰"
        case .tulip: return "郁金香"
        case .lily: return "百合"
        case .carnation: return "康乃馨"
        case .sunflower: return "向日葵"
        case .hydrangea: return "绣球花"
        case .gypsophila: return "满天星"
        case .greenery: return "配叶"
        case .peony: return "芍药/牡丹"
        case .lavender: return "薰衣草"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .rose: return "🌹"
        case .tulip: return "🌷"
        case .lily: return "💐"
        case .carnation: return "🌸"
        case .sunflower: return "🌻"
        case .hydrangea: return "💠"
        case .gypsophila: return "✨"
        case .greenery: return "🌿"
        case .peony: return "🪷"
        case .lavender: return "🪻"
        case .other: return "🌼"
        }
    }
}

// MARK: - 花束中的花卉项
struct BouquetItem: Identifiable {
    var id: String = UUID().uuidString
    let flower: Flower
    var quantity: Int
    var position: CGPoint  // 在预览中的位置
    var scale: CGFloat = 1.0
    var rotation: Double = 0
}

// MARK: - 花束
struct Bouquet: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var items: [BouquetItem]
    var wrappingStyle: WrappingStyle
    var ribbonColor: Color
    var note: String
    let createdAt: Date
    
    var totalPrice: Double {
        items.reduce(0) { $0 + ($1.flower.price * Double($1.quantity)) } + wrappingStyle.price
    }
    
    var totalFlowers: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
}

// MARK: - 包装样式
enum WrappingStyle: String, CaseIterable {
    case kraft = "牛皮纸"
    case transparent = "透明纸"
    case colorful = "彩色纸"
    case luxury = "高级礼盒"
    case basket = "花篮"
    
    var price: Double {
        switch self {
        case .kraft: return 15
        case .transparent: return 12
        case .colorful: return 18
        case .luxury: return 58
        case .basket: return 45
        }
    }
    
    var icon: String {
        switch self {
        case .kraft: return "📦"
        case .transparent: return "🎁"
        case .colorful: return "🎀"
        case .luxury: return "💎"
        case .basket: return "🧺"
        }
    }
}

// MARK: - 订单
struct FlowerOrder: Identifiable {
    let id = UUID()
    let bouquet: Bouquet
    let customerName: String
    let customerPhone: String
    let deliveryAddress: String
    let deliveryDate: Date
    let specialRequests: String
    var status: OrderStatus
    let createdAt: Date
}

enum OrderStatus: String {
    case pending = "待确认"
    case confirmed = "已确认"
    case preparing = "制作中"
    case ready = "已完成"
    case delivered = "已送达"
}

// MARK: - 示例数据
extension Flower {
    static let sampleFlowers: [Flower] = [
        // 玫瑰
        Flower(name: "红玫瑰", englishName: "Red Rose", color: .red, price: 8, emoji: "🌹", category: .rose, categoryName: "Rose", description: "热情的红玫瑰，代表热烈的爱", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Year-round", colorName: "Red"),
        Flower(name: "粉玫瑰", englishName: "Pink Rose", color: .pink, price: 8, emoji: "🌹", category: .rose, categoryName: "Rose", description: "温柔的粉玫瑰，代表初恋", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Year-round", colorName: "Pink"),
        Flower(name: "白玫瑰", englishName: "White Rose", color: .white, price: 8, emoji: "🤍", category: .rose, categoryName: "Rose", description: "纯洁的白玫瑰，代表纯真", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Year-round", colorName: "White"),
        Flower(name: "香槟玫瑰", englishName: "Champagne Rose", color: Color(red: 0.95, green: 0.9, blue: 0.8), price: 10, emoji: "🌹", category: .rose, categoryName: "Rose", description: "优雅的香槟玫瑰", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Year-round", colorName: "Champagne"),
        
        // 郁金香
        Flower(name: "红郁金香", englishName: "Red Tulip", color: .red, price: 6, emoji: "🌷", category: .tulip, categoryName: "Tulip", description: "热情奔放的红郁金香", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Spring", colorName: "Red"),
        Flower(name: "粉郁金香", englishName: "Pink Tulip", color: .pink, price: 6, emoji: "🌷", category: .tulip, categoryName: "Tulip", description: "可爱的粉郁金香", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Spring", colorName: "Pink"),
        Flower(name: "紫郁金香", englishName: "Purple Tulip", color: .purple, price: 7, emoji: "🌷", category: .tulip, categoryName: "Tulip", description: "神秘的紫郁金香", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Spring", colorName: "Purple"),
        
        // 百合
        Flower(name: "白百合", englishName: "White Lily", color: .white, price: 12, emoji: "💐", category: .lily, categoryName: "Lily", description: "高雅的白百合，百年好合", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Summer", colorName: "White"),
        Flower(name: "粉百合", englishName: "Pink Lily", color: .pink, price: 12, emoji: "💐", category: .lily, categoryName: "Lily", description: "浪漫的粉百合", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Summer", colorName: "Pink"),
        
        // 康乃馨
        Flower(name: "红康乃馨", englishName: "Red Carnation", color: .red, price: 5, emoji: "🌸", category: .carnation, categoryName: "Carnation", description: "母爱的象征", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Year-round", colorName: "Red"),
        Flower(name: "粉康乃馨", englishName: "Pink Carnation", color: .pink, price: 5, emoji: "🌸", category: .carnation, categoryName: "Carnation", description: "感恩与祝福", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Year-round", colorName: "Pink"),
        
        // 向日葵
        Flower(name: "向日葵", englishName: "Sunflower", color: .yellow, price: 10, emoji: "🌻", category: .sunflower, categoryName: "Sunflower", description: "阳光积极，充满希望", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Summer", colorName: "Yellow"),
        
        // 绣球花
        Flower(name: "蓝绣球", englishName: "Blue Hydrangea", color: .blue, price: 25, emoji: "💠", category: .hydrangea, categoryName: "Hydrangea", description: "浪漫的蓝色绣球", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Summer", colorName: "Blue"),
        Flower(name: "粉绣球", englishName: "Pink Hydrangea", color: .pink, price: 25, emoji: "💠", category: .hydrangea, categoryName: "Hydrangea", description: "甜美的粉色绣球", imageURL: nil, inventoryCode: nil, unit: "stem", season: "Summer", colorName: "Pink"),
        
        // 满天星
        Flower(name: "白满天星", englishName: "White Gypsophila", color: .white, price: 15, emoji: "✨", category: .gypsophila, categoryName: "Gypsophila", description: "浪漫的配花", imageURL: nil, inventoryCode: nil, unit: "bunch", season: "Year-round", colorName: "White"),
        Flower(name: "粉满天星", englishName: "Pink Gypsophila", color: .pink, price: 18, emoji: "✨", category: .gypsophila, categoryName: "Gypsophila", description: "梦幻的粉色满天星", imageURL: nil, inventoryCode: nil, unit: "bunch", season: "Year-round", colorName: "Pink"),
        
        // 配叶
        Flower(name: "尤加利叶", englishName: "Eucalyptus", color: .green, price: 8, emoji: "🌿", category: .greenery, categoryName: "Greenery", description: "清新的配叶", imageURL: nil, inventoryCode: nil, unit: "bunch", season: "Year-round", colorName: "Green"),
        Flower(name: "蕨类叶", englishName: "Fern", color: .green, price: 5, emoji: "🌿", category: .greenery, categoryName: "Greenery", description: "自然的蕨类", imageURL: nil, inventoryCode: nil, unit: "bunch", season: "Year-round", colorName: "Green"),
    ]
}
