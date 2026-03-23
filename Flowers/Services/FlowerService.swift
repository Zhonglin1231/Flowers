//
//  FlowerService.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import Foundation
import FirebaseFirestore
import Combine

// MARK: - 花卉服务
class FlowerService: ObservableObject {
    private let db = FirebaseManager.shared.db
    private var listener: ListenerRegistration?
    
    @Published var flowers: [FlowerData] = []
    @Published var hasResolvedFlowers = false
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        fetchFlowers()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - 获取所有花卉（实时监听）
    func fetchFlowers() {
        isLoading = true
        hasResolvedFlowers = false
        
        listener = db.collection("flowers")
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                self?.hasResolvedFlowers = true
                
                if let error = error {
                    self?.error = error.localizedDescription
                    self?.flowers = []
                    print("Error fetching flowers: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.flowers = []
                    return
                }
                
                self?.flowers = documents.compactMap { doc in
                    FlowerData(documentID: doc.documentID, data: doc.data())
                }
                .sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            }
    }
    
    // MARK: - 按分类获取花卉
    func fetchFlowersByCategory(_ category: String, completion: @escaping ([FlowerData]) -> Void) {
        db.collection("flowers")
            .whereField("category", isEqualTo: category)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching flowers by category: \(error)")
                    completion([])
                    return
                }
                
                let flowers = snapshot?.documents.compactMap { doc in
                    FlowerData(documentID: doc.documentID, data: doc.data())
                } ?? []
                
                completion(flowers)
            }
    }
    
    // MARK: - 添加示例花卉数据（首次初始化用）
    func seedSampleFlowers() {
        let sampleFlowers: [[String: Any]] = [
            ["id": "dusty-rose", "name": "Dusty Rose", "category": "Rose", "color": "Blush Pink", "price": 4.5, "description": "Soft pink rose with muted tones for romantic arrangements.", "image": "https://images.unsplash.com/photo-1595483416504-65b0328153c1?auto=format&fit=crop&w=1200&q=80", "inventory_code": "R-001", "stockQuantity": 24, "unit": "stem", "season": "Year-round"],
            ["id": "pink-peony", "name": "Pink Peony", "category": "Peony", "color": "Coral", "price": 8.5, "description": "Lush seasonal bloom with layered petals and strong visual impact.", "image": "https://images.unsplash.com/photo-1588457776180-4206b4909301?auto=format&fit=crop&w=1200&q=80", "inventory_code": "P-017", "stockQuantity": 12, "unit": "stem", "season": "Spring-Summer"],
            ["id": "white-lily", "name": "White Lily", "category": "Lily", "color": "White", "price": 7.0, "description": "Elegant focal flower for calm and premium bouquet styles.", "image": "https://images.unsplash.com/photo-1562690868-60bbe7293e94?auto=format&fit=crop&w=1200&q=80", "inventory_code": "L-011", "stockQuantity": 14, "unit": "stem", "season": "Summer"],
            ["id": "hydrangea", "name": "Hydrangea", "category": "Hydrangea", "color": "Mixed", "price": 9.0, "description": "Large-volume bloom for statement bouquets and installations.", "image": "https://images.unsplash.com/photo-1597848212624-c84e6d3b6166?auto=format&fit=crop&w=1200&q=80", "inventory_code": "H-033", "stockQuantity": 10, "unit": "stem", "season": "Summer"],
            ["id": "sunflower", "name": "Sunflower", "category": "Sunflower", "color": "Yellow", "price": 6.5, "description": "Bright and uplifting flower for graduation and celebration bouquets.", "image": "https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80", "inventory_code": "S-006", "stockQuantity": 18, "unit": "stem", "season": "Summer-Autumn"],
            ["id": "lavender", "name": "Lavender", "category": "Lavender", "color": "Lilac", "price": 7.5, "description": "Aromatic bundle used for texture, fragrance, and dried work.", "image": "https://images.unsplash.com/photo-1468327768560-75b778cbb551?auto=format&fit=crop&w=1200&q=80", "inventory_code": "L-022", "stockQuantity": 9, "unit": "bunch", "season": "Summer-Autumn"],
            ["id": "gypsophila", "name": "Gypsophila", "category": "Gypsophila", "color": "White", "price": 5.5, "description": "Cloud-like filler flower that softens the bouquet silhouette.", "image": "https://images.unsplash.com/photo-1525310072745-f49212b5ac6d?auto=format&fit=crop&w=1200&q=80", "inventory_code": "G-008", "stockQuantity": 16, "unit": "bunch", "season": "Year-round"],
            ["id": "eucalyptus", "name": "Eucalyptus", "category": "Greenery", "color": "Sage Green", "price": 4.0, "description": "Fresh greenery that adds structure and modern texture.", "image": "https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=1200&q=80", "inventory_code": "G-031", "stockQuantity": 15, "unit": "bunch", "season": "Year-round"]
        ]
        
        let batch = db.batch()
        
        for flower in sampleFlowers {
            let docId = flower["id"] as? String ?? UUID().uuidString
            let docRef = db.collection("flowers").document(docId)
            batch.setData(flower, forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error seeding flowers: \(error)")
            } else {
                print("Sample flowers seeded successfully!")
            }
        }
    }
}
