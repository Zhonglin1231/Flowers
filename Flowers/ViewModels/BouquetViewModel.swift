//
//  BouquetViewModel.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import SwiftUI
import Combine

class BouquetViewModel: ObservableObject {
    @Published var currentBouquet: Bouquet
    @Published var availableFlowers: [Flower] = []
    @Published var selectedCategory: FlowerCategory? = nil
    @Published var savedBouquets: [Bouquet] = []
    @Published var orders: [FlowerOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Firebase 服务
    private let flowerService = FlowerService()
    private let orderService = OrderService()
    private let bouquetService = BouquetService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.currentBouquet = Bouquet(
            name: "我的花束",
            items: [],
            wrappingStyle: .kraft,
            ribbonColor: .pink,
            note: "",
            createdAt: Date()
        )
        
        // 订阅花卉服务的数据变化
        setupBindings()
        
        // 加载本地示例数据作为后备
        loadLocalFlowersIfNeeded()
    }
    
    // MARK: - 设置数据绑定
    private func setupBindings() {
        // 监听从 Firebase 获取的花卉数据
        flowerService.$flowers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] flowerDataList in
                if !flowerDataList.isEmpty {
                    self?.availableFlowers = flowerDataList.map { $0.toFlower() }
                }
            }
            .store(in: &cancellables)
        
        // 监听加载状态
        flowerService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        // 监听错误
        flowerService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
    
    // MARK: - 如果 Firebase 没有数据，加载本地示例
    private func loadLocalFlowersIfNeeded() {
        // 延迟检查，如果 Firebase 没有返回数据，使用本地数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.availableFlowers.isEmpty == true {
                self?.availableFlowers = Flower.sampleFlowers
            }
        }
    }
    
    // MARK: - 初始化 Firebase 示例数据
    func seedFlowersToFirebase() {
        flowerService.seedSampleFlowers()
    }
    
    // MARK: - 花卉筛选
    var filteredFlowers: [Flower] {
        if let category = selectedCategory {
            return availableFlowers.filter { $0.category == category }
        }
        return availableFlowers
    }
    
    // MARK: - 添加花卉到花束
    func addFlower(_ flower: Flower) {
        // 检查是否已存在
        if let index = currentBouquet.items.firstIndex(where: { $0.flower.id == flower.id }) {
            currentBouquet.items[index].quantity += 1
        } else {
            // 随机生成位置
            let randomX = CGFloat.random(in: 80...280)
            let randomY = CGFloat.random(in: 100...300)
            let randomRotation = Double.random(in: -30...30)
            
            let item = BouquetItem(
                flower: flower,
                quantity: 1,
                position: CGPoint(x: randomX, y: randomY),
                scale: 1.0,
                rotation: randomRotation
            )
            currentBouquet.items.append(item)
        }
    }
    
    // MARK: - 减少花卉数量
    func decreaseFlower(_ item: BouquetItem) {
        if let index = currentBouquet.items.firstIndex(where: { $0.id == item.id }) {
            if currentBouquet.items[index].quantity > 1 {
                currentBouquet.items[index].quantity -= 1
            } else {
                currentBouquet.items.remove(at: index)
            }
        }
    }
    
    // MARK: - 移除花卉
    func removeFlower(_ item: BouquetItem) {
        currentBouquet.items.removeAll { $0.id == item.id }
    }
    
    // MARK: - 更新花卉位置
    func updatePosition(for itemId: String, to position: CGPoint) {
        if let index = currentBouquet.items.firstIndex(where: { $0.id == itemId }) {
            currentBouquet.items[index].position = position
        }
    }
    
    // MARK: - 更新花卉缩放
    func updateScale(for itemId: String, to scale: CGFloat) {
        if let index = currentBouquet.items.firstIndex(where: { $0.id == itemId }) {
            currentBouquet.items[index].scale = scale
        }
    }
    
    // MARK: - 更新花卉旋转
    func updateRotation(for itemId: String, to rotation: Double) {
        if let index = currentBouquet.items.firstIndex(where: { $0.id == itemId }) {
            currentBouquet.items[index].rotation = rotation
        }
    }
    
    // MARK: - 更换包装样式
    func setWrappingStyle(_ style: WrappingStyle) {
        currentBouquet.wrappingStyle = style
    }
    
    // MARK: - 设置丝带颜色
    func setRibbonColor(_ color: Color) {
        currentBouquet.ribbonColor = color
    }
    
    // MARK: - 清空花束
    func clearBouquet() {
        currentBouquet = Bouquet(
            name: "我的花束",
            items: [],
            wrappingStyle: .kraft,
            ribbonColor: .pink,
            note: "",
            createdAt: Date()
        )
    }
    
    // MARK: - 应用 AI 推荐到当前花束
    func applyAISelection(_ selections: [AIBouquetSelection], requirement: String) {
        clearBouquet()
        
        let trimmedRequirement = requirement.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRequirement.isEmpty {
            currentBouquet.name = String(trimmedRequirement.prefix(18))
            currentBouquet.note = "AI需求：\(trimmedRequirement)"
        }
        
        for selection in selections where selection.isSelected {
            for _ in 0..<selection.quantity {
                addFlower(selection.flower)
            }
        }
    }
    
    // MARK: - 保存花束到 Firebase
    func saveBouquet(completion: ((Bool) -> Void)? = nil) {
        bouquetService.saveBouquet(currentBouquet) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    guard let self else {
                        completion?(true)
                        return
                    }
                    self.savedBouquets.append(self.currentBouquet)
                    completion?(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - 提交订单到 Firebase
    func submitOrder(
        customerName: String,
        customerPhone: String,
        deliveryAddress: String,
        deliveryDate: Date,
        specialRequests: String,
        completion: @escaping (Result<FlowerOrder, Error>) -> Void
    ) {
        orderService.submitOrder(
            bouquet: currentBouquet,
            customerName: customerName,
            customerPhone: customerPhone,
            deliveryAddress: deliveryAddress,
            deliveryDate: deliveryDate,
            specialRequests: specialRequests
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    guard let self else {
                        return
                    }
                    // 创建本地订单对象用于显示
                    let order = FlowerOrder(
                        bouquet: self.currentBouquet,
                        customerName: customerName,
                        customerPhone: customerPhone,
                        deliveryAddress: deliveryAddress,
                        deliveryDate: deliveryDate,
                        specialRequests: specialRequests,
                        status: .pending,
                        createdAt: Date()
                    )
                    self.orders.append(order)
                    completion(.success(order))
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 生成订单描述（发送给商家）
    func generateOrderDescription() -> String {
        var description = "【花束订单】\n"
        description += "花束名称：\(currentBouquet.name)\n"
        description += "------------------------\n"
        description += "花材清单：\n"
        
        for item in currentBouquet.items {
            description += "  • \(item.flower.name) x \(item.quantity) - ¥\(item.flower.price * Double(item.quantity))\n"
        }
        
        description += "------------------------\n"
        description += "包装样式：\(currentBouquet.wrappingStyle.rawValue) \(currentBouquet.wrappingStyle.icon)\n"
        description += "包装费用：¥\(currentBouquet.wrappingStyle.price)\n"
        description += "------------------------\n"
        description += "总计：¥\(String(format: "%.2f", currentBouquet.totalPrice))\n"
        
        if !currentBouquet.note.isEmpty {
            description += "备注：\(currentBouquet.note)\n"
        }
        
        return description
    }
}
