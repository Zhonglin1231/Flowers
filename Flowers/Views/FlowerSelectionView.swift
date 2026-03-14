//
//  FlowerSelectionView.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import SwiftUI

struct FlowerSelectionView: View {
    @ObservedObject var viewModel: BouquetViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分类选择器
                CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
                
                // 花卉列表
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.filteredFlowers) { flower in
                            FlowerCard(flower: flower) {
                                viewModel.addFlower(flower)
                                // 添加触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("选择花卉")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 分类筛选视图
struct CategoryFilterView: View {
    @Binding var selectedCategory: FlowerCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部按钮
                CategoryChip(
                    title: "全部",
                    icon: "🌸",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // 各分类按钮
                ForEach(FlowerCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - 分类标签
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.pink.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? .pink : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - 花卉卡片
struct FlowerCard: View {
    let flower: Flower
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 花卉图标
            ZStack {
                Circle()
                    .fill(flower.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if let imageURL = flower.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Text(flower.emoji)
                                .font(.system(size: 40))
                        @unknown default:
                            Text(flower.emoji)
                                .font(.system(size: 40))
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                } else {
                    Text(flower.emoji)
                        .font(.system(size: 40))
                }
            }
            
            // 花卉名称
            Text(flower.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            // 英文名
            Text(flower.englishName)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // 价格
            Text("¥\(String(format: "%.1f", flower.price))/\(flower.unitDisplayName)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.pink)
            
            // 添加按钮
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.pink)
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    FlowerSelectionView(
        viewModel: BouquetViewModel(),
        isPresented: .constant(true)
    )
}
