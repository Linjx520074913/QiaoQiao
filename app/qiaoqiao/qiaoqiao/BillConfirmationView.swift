//
//  BillConfirmationView.swift
//  qiaoqiao
//
//  账单预分析确认页 - 仿系统弹窗
//

import SwiftUI

// MARK: - 账单确认页
struct BillConfirmationView: View {
    let bill: PendingBill
    let onConfirm: () -> Void
    let onEdit: () -> Void

    @State private var isPresented = false
    @State private var cardOffset: CGFloat = 1000

    var body: some View {
        ZStack {
            // 半透明模糊背景
            Color.black
                .opacity(isPresented ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // 卡片浮层
            VStack(spacing: 0) {
                Spacer()

                BillConfirmationCard(
                    bill: bill,
                    onConfirm: {
                        confirmWithAnimation()
                    },
                    onEdit: {
                        onEdit()
                    }
                )
                .offset(y: cardOffset)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            presentWithAnimation()
        }
    }

    // MARK: - 出现动画（仿系统 Sheet）
    private func presentWithAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
            isPresented = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0)) {
            cardOffset = 0
        }
    }

    // MARK: - 消失动画
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.25)) {
            isPresented = false
            cardOffset = 1000
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 动画完成后回调
        }
    }

    // MARK: - 确认动画
    private func confirmWithAnimation() {
        // 轻微缩放反馈
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cardOffset = -20
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                isPresented = false
                cardOffset = 1000
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onConfirm()
        }
    }
}

// MARK: - 卡片内容
struct BillConfirmationCard: View {
    let bill: PendingBill
    let onConfirm: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航
            HStack {
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                }
                .opacity(0) // 隐藏但保持布局

                Spacer()

                Text("扫描完成")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Button(action: onEdit) {
                    Text("编辑")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(.systemBackground)
                    .overlay(
                        Divider()
                            .background(Color(.separator)),
                        alignment: .bottom
                    )
            )

            // 账单内容
            ScrollView {
                VStack(spacing: 24) {
                    // 商家图标
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "building.2.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 32)

                    // 商家名称
                    Text(bill.merchantName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    // 时间
                    Text(formatTime(bill.timestamp))
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)

                    // 分隔线
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)

                    // 金额区域
                    VStack(spacing: 12) {
                        Text("总金额")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Text("¥\(String(format: "%.2f", bill.amount))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)

                    // 分类标签（如果有）
                    if let category = bill.category {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)

                            Text(category)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                .padding(.bottom, 32)
            }

            // 底部按钮区域
            VStack(spacing: 12) {
                // 主按钮：确认入账
                Button(action: onConfirm) {
                    Text("确认入账")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: Color.orange.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }

                // 说明文字
                Text("点击确认后将自动记入账单")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .background(
                Color(.systemBackground)
                    .overlay(
                        Divider()
                            .background(Color(.separator)),
                        alignment: .top
                    )
            )
        }
        .frame(maxWidth: 480) // 限制最大宽度（iPad 适配）
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 30,
                    x: 0,
                    y: 10
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - 时间格式化
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "今天 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 预览
#Preview {
    BillConfirmationView(
        bill: PendingBill.mockExample,
        onConfirm: {
            print("确认入账")
        },
        onEdit: {
            print("编辑账单")
        }
    )
}
