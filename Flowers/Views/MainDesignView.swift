//
//  MainDesignView.swift
//  Flowers
//
//  Created by Zhong Lin on 2/2/2026.
//

import SwiftUI

struct MainDesignView: View {
    @StateObject private var viewModel = BouquetViewModel()
    
    @State private var showingAIPreviewLab = false
    @State private var showingFlowerSelection = false
    @State private var showingWrappingStyle = false
    @State private var showingOrderForm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 花束预览区域
                BouquetPreviewView(viewModel: viewModel)
                
                // 花材清单
                BouquetItemListView(viewModel: viewModel)
                
                // 底部操作栏
                BottomActionBar(
                    canSubmit: !viewModel.currentBouquet.items.isEmpty,
                    onAddFlower: {
                        showingFlowerSelection = true
                    },
                    onCustomize: {
                        showingWrappingStyle = true
                    },
                    onSubmit: {
                        showingOrderForm = true
                    }
                )
            }
            .navigationTitle("花束设计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAIPreviewLab = true
                    } label: {
                        Label("AI预览", systemImage: "sparkles")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.saveBouquet()
                        }) {
                            Label("保存设计", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: {
                            viewModel.clearBouquet()
                        }) {
                            Label("重新开始", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFlowerSelection) {
                FlowerSelectionView(
                    viewModel: viewModel,
                    isPresented: $showingFlowerSelection
                )
            }
            .sheet(isPresented: $showingAIPreviewLab) {
                AIBouquetPreviewView(
                    bouquetViewModel: viewModel,
                    isPresented: $showingAIPreviewLab
                )
            }
            .sheet(isPresented: $showingWrappingStyle) {
                WrappingStyleView(
                    viewModel: viewModel,
                    isPresented: $showingWrappingStyle
                )
            }
            .sheet(isPresented: $showingOrderForm) {
                OrderFormView(
                    viewModel: viewModel,
                    isPresented: $showingOrderForm
                )
            }
        }
    }
}

// MARK: - 底部操作栏
struct BottomActionBar: View {
    let canSubmit: Bool
    let onAddFlower: () -> Void
    let onCustomize: () -> Void
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 添加花卉按钮
            Button(action: onAddFlower) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("添加花卉")
                        .font(.caption)
                }
                .foregroundColor(.pink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.pink.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 包装设置按钮
            Button(action: onCustomize) {
                VStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.title2)
                    Text("包装设置")
                        .font(.caption)
                }
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 提交订单按钮
            Button(action: onSubmit) {
                VStack(spacing: 4) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                    Text("提交订单")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(canSubmit ? Color.pink : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canSubmit)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}

#Preview {
    MainDesignView()
}
