//
//  BouquetService.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - 花束服务（保存和获取用户设计的花束）
class BouquetService: ObservableObject {
    private let db = FirebaseManager.shared.db
    private var listener: ListenerRegistration?
    
    @Published var savedBouquets: [BouquetData] = []
    @Published var catalogBouquets: [BouquetData] = []
    @Published var hasResolvedCatalogBouquets = false
    @Published var isLoading = false
    @Published var error: String?
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - 保存花束设计
    func saveBouquet(_ bouquet: Bouquet, completion: @escaping (Result<String, Error>) -> Void) {
        let bouquetItems = bouquet.items.map { item in
            [
                "flowerId": item.flower.id,
                "flowerName": item.flower.name,
                "flowerEmoji": item.flower.emoji,
                "flowerPrice": item.flower.price,
                "quantity": item.quantity,
                "positionX": item.position.x,
                "positionY": item.position.y,
                "scale": item.scale,
                "rotation": item.rotation
            ] as [String: Any]
        }
        
        let bouquetData: [String: Any] = [
            "name": bouquet.name,
            "items": bouquetItems,
            "wrappingStyle": bouquet.wrappingStyle.rawValue,
            "ribbonColorHex": bouquet.ribbonColor.toHex(),
            "note": bouquet.note,
            "createdAt": Timestamp(date: bouquet.createdAt),
            "userId": FirebaseManager.shared.currentUser?.uid ?? "",
            "totalPrice": bouquet.totalPrice
        ]
        
        db.collection("bouquets").addDocument(data: bouquetData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("花束保存成功"))
            }
        }
    }
    
    // MARK: - 获取用户保存的花束
    func fetchUserBouquets() {
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            // 演示模式：获取所有花束
            fetchAllBouquets()
            return
        }
        
        isLoading = true
        listener?.remove()
        
        listener = db.collection("bouquets")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.savedBouquets = snapshot?.documents.compactMap { doc in
                    self?.parseBouquetDocument(doc)
                } ?? []
            }
    }
    
    // MARK: - 获取所有保存的花束
    private func fetchAllBouquets() {
        isLoading = true
        listener?.remove()
        
        listener = db.collection("bouquets")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.savedBouquets = snapshot?.documents.compactMap { doc in
                    self?.parseBouquetDocument(doc)
                } ?? []
            }
    }
    
    // MARK: - 获取店铺展示花束
    func fetchCatalogBouquets() {
        isLoading = true
        hasResolvedCatalogBouquets = false
        listener?.remove()
        
        listener = db.collection("bouquets")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                self?.hasResolvedCatalogBouquets = true
                
                if let error = error {
                    self?.error = error.localizedDescription
                    self?.catalogBouquets = []
                    return
                }
                
                let bouquets = snapshot?.documents.compactMap { doc in
                    self?.parseBouquetDocument(doc)
                } ?? []
                
                let publishedBouquets = bouquets.filter { bouquet in
                    bouquet.isPublished != false && bouquet.isTemplate != true
                }
                
                self?.catalogBouquets = publishedBouquets.isEmpty ? bouquets : publishedBouquets
            }
    }
    
    // MARK: - 解析花束文档
    private func parseBouquetDocument(_ doc: QueryDocumentSnapshot) -> BouquetData? {
        let data = doc.data()
        
        let resolvedName = ((data["name"] as? String) ?? (data["title"] as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolvedName.isEmpty else {
            return nil
        }
        
        let itemsArray = data["items"] as? [[String: Any]] ?? []
        let items = itemsArray.map { itemDict in
            BouquetItemData(
                flowerId: itemDict["flowerId"] as? String ?? "",
                flowerName: itemDict["flowerName"] as? String ?? "",
                flowerEmoji: itemDict["flowerEmoji"] as? String ?? "🌸",
                flowerPrice: itemDict["flowerPrice"] as? Double ?? 0,
                quantity: itemDict["quantity"] as? Int ?? 1,
                positionX: itemDict["positionX"] as? Double ?? 0,
                positionY: itemDict["positionY"] as? Double ?? 0,
                scale: itemDict["scale"] as? Double ?? 1,
                rotation: itemDict["rotation"] as? Double ?? 0
            )
        }
        
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let derivedTotalPrice = items.reduce(0) { partial, item in
            partial + (item.flowerPrice * Double(item.quantity))
        }
        let totalPrice = (data["totalPrice"] as? NSNumber)?.doubleValue
            ?? (data["price"] as? NSNumber)?.doubleValue
            ?? derivedTotalPrice
        
        return BouquetData(
            id: doc.documentID,
            name: resolvedName,
            items: items,
            wrappingStyle: data["wrappingStyle"] as? String ?? "牛皮纸",
            ribbonColorHex: data["ribbonColorHex"] as? String ?? "#FFC0CB",
            note: (data["note"] as? String) ?? (data["description"] as? String) ?? "",
            createdAt: createdAt,
            userId: data["userId"] as? String,
            totalPrice: totalPrice,
            imageURL: (data["imageURL"] as? String) ?? (data["image"] as? String),
            tagline: (data["tagline"] as? String) ?? (data["subtitle"] as? String),
            descriptionLines: data["descriptionLines"] as? [String],
            longDescription: data["longDescription"] as? [String],
            isPublished: data["isPublished"] as? Bool,
            isTemplate: data["isTemplate"] as? Bool
        )
    }
    
    // MARK: - 删除花束
    func deleteBouquet(bouquetId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("bouquets").document(bouquetId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
