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
    let inventoryItems: [BouquetItemData]
}

struct SubmittedStorefrontOrder {
    let documentID: String
    let sourceOrderId: String
    let createdAt: Date
}

private struct InventoryDeductionLine {
    let flowerId: String
    let flowerName: String
    let quantity: Int
}

private struct InventoryWriteTarget {
    let documentRef: DocumentReference
    let fieldName: String
    let updatedQuantity: Int
}

private enum OrderServiceError: LocalizedError {
    case invalidFlowerReference(String)
    case flowerNotFound(String)
    case missingStockQuantity(String)
    case missingInventoryCode(String)
    case inventoryRecordNotFound(String)
    case insufficientStock(flowerName: String, available: Int, requested: Int)

    var errorDescription: String? {
        switch self {
        case .invalidFlowerReference(let flowerName):
            return "花材“\(flowerName)”缺少有效的库存 ID，无法提交订单。"
        case .flowerNotFound(let flowerName):
            return "数据库里找不到花材“\(flowerName)”，无法扣减库存。"
        case .missingStockQuantity(let flowerName):
            return "花材“\(flowerName)”还没有配置库存数量。"
        case .missingInventoryCode(let flowerName):
            return "花材“\(flowerName)”没有配置 inventory code，无法扣减库存。"
        case .inventoryRecordNotFound(let code):
            return "库存表里找不到编码为“\(code)”的记录。"
        case let .insufficientStock(flowerName, available, requested):
            return "花材“\(flowerName)”库存不足，当前剩余 \(available)，需要 \(requested)。"
        }
    }
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

    func stopListening() {
        listener?.remove()
        listener = nil
        isLoading = false
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
        let inventoryItems = inventoryLines(from: bouquetItems)
        let orderRef = db.collection("orders").document()
        
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
            "inventoryItems": inventoryItems.map { item in
                [
                    "flowerId": item.flowerId,
                    "flowerName": item.flowerName,
                    "quantity": item.quantity
                ]
            },
            "customerName": customerName,
            "customerPhone": customerPhone,
            "deliveryAddress": deliveryAddress,
            "deliveryDate": Timestamp(date: deliveryDate),
            "specialRequests": specialRequests,
            "status": OrderStatus.pending.rawValue,
            "createdAt": Timestamp(date: Date()),
            "userId": FirebaseManager.shared.currentUser?.uid ?? ""
        ]
        
        submitOrderDocument(
            orderRef: orderRef,
            orderData: orderData,
            inventoryItems: inventoryItems
        ) { error in
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
        let inventoryItems = inventoryLines(from: items)

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
            "inventoryItems": inventoryItems.map { item in
                [
                    "flowerId": item.flowerId,
                    "flowerName": item.flowerName,
                    "quantity": item.quantity
                ]
            },
            "customerName": customerName,
            "customerPhone": customerPhone,
            "status": OrderStatus.pending.rawValue,
            "specialRequests": specialRequests,
            "deliveryDate": Timestamp(date: deliveryDate)
        ]

        submitOrderDocument(
            orderRef: orderRef,
            orderData: orderData,
            inventoryItems: inventoryItems
        ) { error in
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
        listener?.remove()
        
        listener = db.collection("orders")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("Error fetching orders: \(error)")
                    return
                }
                
                self?.orders = (snapshot?.documents.compactMap { doc in
                    self?.parseOrderDocument(doc)
                } ?? [])
                .sorted(by: Self.userOrderHistorySort)
            }
    }
    
    // MARK: - 获取所有订单（商家端使用）
    func fetchAllOrders() {
        isLoading = true
        listener?.remove()
        
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
                flowerPrice: (itemDict["flowerPrice"] as? NSNumber)?.doubleValue
                    ?? (itemDict["flowerPrice"] as? Double ?? 0),
                quantity: (itemDict["quantity"] as? NSNumber)?.intValue
                    ?? (itemDict["quantity"] as? Int ?? 1),
                positionX: (itemDict["positionX"] as? NSNumber)?.doubleValue
                    ?? (itemDict["positionX"] as? Double ?? 0),
                positionY: (itemDict["positionY"] as? NSNumber)?.doubleValue
                    ?? (itemDict["positionY"] as? Double ?? 0),
                scale: (itemDict["scale"] as? NSNumber)?.doubleValue
                    ?? (itemDict["scale"] as? Double ?? 1),
                rotation: (itemDict["rotation"] as? NSNumber)?.doubleValue
                    ?? (itemDict["rotation"] as? Double ?? 0)
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
            totalPrice: (bouquetDict["totalPrice"] as? NSNumber)?.doubleValue
                ?? (bouquetDict["totalPrice"] as? Double ?? 0)
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
        db.collection("orders").document(orderId).updateData([
            "status": OrderStatus.cancelled.rawValue,
            "refundStatus": "退款已原路返回",
            "cancelledAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private static func userOrderHistorySort(_ lhs: OrderData, _ rhs: OrderData) -> Bool {
        let lhsPriority = userOrderHistoryPriority(for: lhs.status)
        let rhsPriority = userOrderHistoryPriority(for: rhs.status)

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return (lhs.id ?? "") > (rhs.id ?? "")
    }

    private static func userOrderHistoryPriority(for status: String) -> Int {
        switch status {
        case OrderStatus.pending.rawValue,
             OrderStatus.confirmed.rawValue,
             OrderStatus.preparing.rawValue:
            return 0
        case OrderStatus.ready.rawValue,
             OrderStatus.delivered.rawValue:
            return 1
        case OrderStatus.cancelled.rawValue:
            return 2
        default:
            return 3
        }
    }

    private func submitOrderDocument(
        orderRef: DocumentReference,
        orderData: [String: Any],
        inventoryItems: [InventoryDeductionLine],
        completion: @escaping (Error?) -> Void
    ) {
        db.runTransaction({ [weak self] transaction, errorPointer in
            guard let self else { return nil }
            var inventoryUpdates: [InventoryWriteTarget] = []

            for item in inventoryItems {
                do {
                    let updateTarget = try self.resolveInventoryWriteTarget(
                        for: item,
                        transaction: transaction
                    )
                    inventoryUpdates.append(updateTarget)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            transaction.setData(orderData, forDocument: orderRef)

            for updateTarget in inventoryUpdates {
                transaction.updateData([
                    updateTarget.fieldName: updateTarget.updatedQuantity,
                    "isAvailable": updateTarget.updatedQuantity > 0
                ], forDocument: updateTarget.documentRef)
            }

            return nil
        }) { _, error in
            completion(error)
        }
    }

    private func resolveInventoryWriteTarget(
        for item: InventoryDeductionLine,
        transaction: Transaction
    ) throws -> InventoryWriteTarget {
        let flowerRef = db.collection("flowers").document(item.flowerId)
        let flowerSnapshot = try transaction.getDocument(flowerRef)

        guard flowerSnapshot.exists else {
            throw OrderServiceError.flowerNotFound(item.flowerName)
        }

        let flowerData = flowerSnapshot.data() ?? [:]

        if let stockNumber = flowerData["stockQuantity"] as? NSNumber {
            return try buildWriteTarget(
                documentRef: flowerRef,
                fieldName: "stockQuantity",
                currentQuantity: stockNumber.intValue,
                item: item
            )
        }

        let inventoryCode = (flowerData["inventoryCode"] as? String)
            ?? (flowerData["inventory_code"] as? String)
            ?? (flowerData["code"] as? String)

        guard let inventoryCode, !inventoryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OrderServiceError.missingInventoryCode(item.flowerName)
        }

        let inventoryRef = db.collection("inventory").document(inventoryCode)
        let inventorySnapshot = try transaction.getDocument(inventoryRef)

        guard inventorySnapshot.exists else {
            throw OrderServiceError.inventoryRecordNotFound(inventoryCode)
        }

        let inventoryData = inventorySnapshot.data() ?? [:]
        guard let stockNumber = inventoryData["stock"] as? NSNumber else {
            throw OrderServiceError.missingStockQuantity(item.flowerName)
        }

        return try buildWriteTarget(
            documentRef: inventoryRef,
            fieldName: "stock",
            currentQuantity: stockNumber.intValue,
            item: item
        )
    }

    private func buildWriteTarget(
        documentRef: DocumentReference,
        fieldName: String,
        currentQuantity: Int,
        item: InventoryDeductionLine
    ) throws -> InventoryWriteTarget {
        let updatedQuantity = currentQuantity - item.quantity

        guard updatedQuantity >= 0 else {
            throw OrderServiceError.insufficientStock(
                flowerName: item.flowerName,
                available: currentQuantity,
                requested: item.quantity
            )
        }

        return InventoryWriteTarget(
            documentRef: documentRef,
            fieldName: fieldName,
            updatedQuantity: updatedQuantity
        )
    }

    private func inventoryLines(from bouquetItems: [BouquetItemData]) -> [InventoryDeductionLine] {
        aggregateInventoryLines(
            bouquetItems.compactMap { item in
                let flowerId = item.flowerId.trimmingCharacters(in: .whitespacesAndNewlines)
                let flowerName = item.flowerName.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !flowerId.isEmpty else { return nil }
                guard item.quantity > 0 else { return nil }

                return InventoryDeductionLine(
                    flowerId: flowerId,
                    flowerName: flowerName.isEmpty ? flowerId : flowerName,
                    quantity: item.quantity
                )
            }
        )
    }

    private func inventoryLines(from storefrontItems: [StorefrontOrderLineItem]) -> [InventoryDeductionLine] {
        aggregateInventoryLines(
            storefrontItems.flatMap { storefrontItem in
                storefrontItem.inventoryItems.compactMap { inventoryItem in
                    let flowerId = inventoryItem.flowerId.trimmingCharacters(in: .whitespacesAndNewlines)
                    let flowerName = inventoryItem.flowerName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let totalQuantity = inventoryItem.quantity * storefrontItem.quantity

                    guard !flowerId.isEmpty else { return nil }
                    guard totalQuantity > 0 else { return nil }

                    return InventoryDeductionLine(
                        flowerId: flowerId,
                        flowerName: flowerName.isEmpty ? flowerId : flowerName,
                        quantity: totalQuantity
                    )
                }
            }
        )
    }

    private func aggregateInventoryLines(_ items: [InventoryDeductionLine]) -> [InventoryDeductionLine] {
        var aggregated: [String: InventoryDeductionLine] = [:]

        for item in items {
            if let existing = aggregated[item.flowerId] {
                aggregated[item.flowerId] = InventoryDeductionLine(
                    flowerId: item.flowerId,
                    flowerName: item.flowerName,
                    quantity: existing.quantity + item.quantity
                )
            } else {
                aggregated[item.flowerId] = item
            }
        }

        return Array(aggregated.values)
    }
}
