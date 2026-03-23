//
//  OrderService.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

struct StorefrontOrderLineItem {
    let productId: String
    let productName: String
    let unitPrice: Double
    let quantity: Int
}

struct SubmittedStorefrontOrder {
    let documentID: String
    let sourceOrderId: String
    let createdAt: Date
}

// MARK: - 订单服务
class OrderService: ObservableObject {
    private let db = FirebaseManager.shared.db
    private var listener: ListenerRegistration?
    
    @Published var orders: [OrderData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - 提交订单
    func submitOrder(
        bouquet: Bouquet,
        customerName: String,
        customerPhone: String,
        deliveryAddress: String,
        deliveryDate: Date,
        specialRequests: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // 转换花束数据
        let sourceOrderId = String(format: "#%04d", Int(Date().timeIntervalSince1970) % 10_000)
        let bouquetItems = bouquet.items.map { item in
            BouquetItemData(
                flowerId: item.flower.id,
                flowerName: item.flower.name,
                flowerEmoji: item.flower.emoji,
                flowerPrice: item.flower.price,
                quantity: item.quantity,
                positionX: item.position.x,
                positionY: item.position.y,
                scale: item.scale,
                rotation: item.rotation
            )
        }
        
        let bouquetData = BouquetData(
            id: nil,
            name: bouquet.name,
            items: bouquetItems,
            wrappingStyle: bouquet.wrappingStyle.rawValue,
            ribbonColorHex: bouquet.ribbonColor.toHex(),
            note: bouquet.note,
            createdAt: bouquet.createdAt,
            userId: FirebaseManager.shared.currentUser?.uid,
            totalPrice: bouquet.totalPrice
        )
        
        let orderData: [String: Any] = [
            "sourceOrderId": sourceOrderId,
            "bouquetData": [
                "name": bouquetData.name,
                "items": bouquetItems.map { item in
                    [
                        "flowerId": item.flowerId,
                        "flowerName": item.flowerName,
                        "flowerEmoji": item.flowerEmoji,
                        "flowerPrice": item.flowerPrice,
                        "quantity": item.quantity,
                        "positionX": item.positionX,
                        "positionY": item.positionY,
                        "scale": item.scale,
                        "rotation": item.rotation
                    ]
                },
                "wrappingStyle": bouquetData.wrappingStyle,
                "ribbonColorHex": bouquetData.ribbonColorHex,
                "note": bouquetData.note,
                "createdAt": Timestamp(date: bouquetData.createdAt),
                "totalPrice": bouquetData.totalPrice
            ],
            "customerName": customerName,
            "customerPhone": customerPhone,
            "deliveryAddress": deliveryAddress,
            "deliveryDate": Timestamp(date: deliveryDate),
            "specialRequests": specialRequests,
            "status": OrderStatus.pending.rawValue,
            "createdAt": Timestamp(date: Date()),
            "userId": FirebaseManager.shared.currentUser?.uid ?? ""
        ]
        
        db.collection("orders").addDocument(data: orderData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("订单提交成功"))
            }
        }
    }

    func submitStorefrontOrder(
        items: [StorefrontOrderLineItem],
        orderName: String,
        customerName: String,
        customerPhone: String,
        deliveryAddress: String,
        deliveryDate: Date,
        specialRequests: String,
        totalPrice: Double,
        sourceOrderId: String,
        completion: @escaping (Result<SubmittedStorefrontOrder, Error>) -> Void
    ) {
        guard !items.isEmpty else {
            completion(.failure(NSError(
                domain: "OrderService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "购物车为空，无法提交订单"]
            )))
            return
        }

        let now = Date()
        let userId = FirebaseManager.shared.currentUser?.uid ?? "guest-demo"
        let orderRef = db.collection("orders").document()

        let orderData: [String: Any] = [
            "sourceOrderId": sourceOrderId,
            "createdAt": Timestamp(date: now),
            "userId": userId,
            "deliveryAddress": deliveryAddress,
            "bouquetData": [
                "ribbonColorHex": "#111111",
                "createdAt": Timestamp(date: now),
                "wrappingStyle": "Store Order",
                "items": items.map { item in
                    [
                        "quantity": item.quantity,
                        "flowerId": item.productId,
                        "flowerPrice": item.unitPrice,
                        "flowerName": item.productName
                    ]
                },
                "note": specialRequests,
                "totalPrice": totalPrice,
                "name": orderName
            ],
            "customerName": customerName,
            "customerPhone": customerPhone,
            "status": OrderStatus.pending.rawValue,
            "specialRequests": specialRequests,
            "deliveryDate": Timestamp(date: deliveryDate)
        ]

        orderRef.setData(orderData) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(SubmittedStorefrontOrder(
                    documentID: orderRef.documentID,
                    sourceOrderId: sourceOrderId,
                    createdAt: now
                )))
            }
        }
    }
    
    // MARK: - 获取用户订单（实时监听）
    func fetchUserOrders() {
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            // 如果用户未登录，获取所有订单（演示用）
            fetchAllOrders()
            return
        }
        
        isLoading = true
        
        listener = db.collection("orders")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("Error fetching orders: \(error)")
                    return
                }
                
                self?.orders = snapshot?.documents.compactMap { doc in
                    self?.parseOrderDocument(doc)
                } ?? []
            }
    }
    
    // MARK: - 获取所有订单（商家端使用）
    func fetchAllOrders() {
        isLoading = true
        
        listener = db.collection("orders")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("Error fetching all orders: \(error)")
                    return
                }
                
                self?.orders = snapshot?.documents.compactMap { doc in
                    self?.parseOrderDocument(doc)
                } ?? []
            }
    }
    
    // MARK: - 解析订单文档
    private func parseOrderDocument(_ doc: QueryDocumentSnapshot) -> OrderData? {
        let data = doc.data()
        
        guard let bouquetDict = data["bouquetData"] as? [String: Any],
              let customerName = data["customerName"] as? String,
              let customerPhone = data["customerPhone"] as? String,
              let deliveryAddress = data["deliveryAddress"] as? String,
              let deliveryTimestamp = data["deliveryDate"] as? Timestamp,
              let status = data["status"] as? String,
              let createdTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        // 解析花束项
        let itemsArray = bouquetDict["items"] as? [[String: Any]] ?? []
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
        
        let bouquetData = BouquetData(
            id: nil,
            name: bouquetDict["name"] as? String ?? "花束",
            items: items,
            wrappingStyle: bouquetDict["wrappingStyle"] as? String ?? "牛皮纸",
            ribbonColorHex: bouquetDict["ribbonColorHex"] as? String ?? "#FFC0CB",
            note: bouquetDict["note"] as? String ?? "",
            createdAt: (bouquetDict["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            userId: data["userId"] as? String,
            totalPrice: bouquetDict["totalPrice"] as? Double ?? 0
        )
        
        return OrderData(
            id: doc.documentID,
            bouquetId: "",
            bouquetData: bouquetData,
            sourceOrderId: data["sourceOrderId"] as? String,
            customerName: customerName,
            customerPhone: customerPhone,
            deliveryAddress: deliveryAddress,
            deliveryDate: deliveryTimestamp.dateValue(),
            specialRequests: data["specialRequests"] as? String ?? "",
            status: status,
            createdAt: createdTimestamp.dateValue(),
            userId: data["userId"] as? String
        )
    }
    
    // MARK: - 更新订单状态
    func updateOrderStatus(orderId: String, status: OrderStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("orders").document(orderId).updateData([
            "status": status.rawValue
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - 取消订单
    func cancelOrder(orderId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("orders").document(orderId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
