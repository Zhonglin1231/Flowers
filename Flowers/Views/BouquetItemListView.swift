//
//  BouquetItemListView.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import SwiftUI

struct BouquetItemListView: View {
    @ObservedObject var viewModel: BouquetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Text("花材清单")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.currentBouquet.items.isEmpty {
                    Button(action: {
                        withAnimation {
                            viewModel.clearBouquet()
                        }
                    }) {
                        Text("清空")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)
            
            if viewModel.currentBouquet.items.isEmpty {
                // 空状态
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "cart")
                            .font(.title)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("还没有添加花卉")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                // 花材列表
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.currentBouquet.items) { item in
                            BouquetItemCard(
                                item: item,
                                onIncrease: {
                                    viewModel.addFlower(item.flower)
                                },
                                onDecrease: {
                                    viewModel.decreaseFlower(item)
                                },
                                onRemove: {
                                    withAnimation {
                                        viewModel.removeFlower(item)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
}

// MARK: - 花材卡片
struct BouquetItemCard: View {
    let item: BouquetItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 删除按钮
            HStack {
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            // 花卉图标
            ZStack {
                Circle()
                    .fill(item.flower.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text(item.flower.emoji)
                    .font(.title2)
            }
            
            // 名称
            Text(item.flower.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
            
            // 单价
            Text("¥\(String(format: "%.0f", item.flower.price))")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // 数量控制
            HStack(spacing: 8) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.pink)
                }
                
                Text("\(item.quantity)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 25)
                
                Button(action: onIncrease) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.pink)
                }
            }
            
            // 小计
            Text("¥\(String(format: "%.0f", item.flower.price * Double(item.quantity)))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.pink)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(width: 126)
    }
}

#Preview {
    let viewModel = BouquetViewModel()
    viewModel.addFlower(Flower.sampleFlowers[0])
    viewModel.addFlower(Flower.sampleFlowers[1])
    viewModel.addFlower(Flower.sampleFlowers[0])
    
    return BouquetItemListView(viewModel: viewModel)
}
