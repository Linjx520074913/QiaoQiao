//
//  BillScanLiveActivity.swift
//  BillScanWidget
//
//  Live Activity UI 定义
//

import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Widget
struct BillScanLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BillScanAttributes.self) { context in
            // 锁屏 / 横幅视图
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.white)
                .activitySystemActionForegroundColor(Color.orange)

        } dynamicIsland: { context in
            // 灵动岛视图
            DynamicIsland {
                // 展开视图
                DynamicIslandExpandedRegion(.leading) {
                    Text("🎉")
                        .font(.title)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.message)
                        .font(.caption)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text("KAPI 账单识别")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

            } compactLeading: {
                // 紧凑模式 - 左侧
                Text("🎉")

            } compactTrailing: {
                // 紧凑模式 - 右侧
                Text("Hi")
                    .font(.caption2)

            } minimal: {
                // 最小模式
                Text("🎉")
            }
        }
    }
}

// MARK: - 锁屏/横幅视图（账单确认卡片）
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<BillScanAttributes>

    var body: some View {
        VStack(spacing: 16) {
            // 顶部标题
            HStack {
                Text("扫描完成")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

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
                    .frame(width: 64, height: 64)

                Text("🍜")
                    .font(.system(size: 32))
            }

            // 商家名称
            Text(context.state.merchantName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)

            // 时间
            Text(formatTime(context.state.timestamp))
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            // 总金额
            VStack(spacing: 8) {
                Text("总金额")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text("¥\(String(format: "%.2f", context.state.amount))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)

            // 账单明细（如果有）
            if let items = context.state.items, !items.isEmpty {
                VStack(spacing: 6) {
                    ForEach(items.prefix(3), id: \.self) { item in
                        HStack {
                            Text(item.name)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            if let qty = item.quantity, qty > 1 {
                                Text("×\(qty)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("¥\(String(format: "%.2f", item.price))")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // 「记账」按钮
            Button(intent: ConfirmBillIntent(billId: context.state.billId)) {
                HStack {
                    Spacer()
                    Text("记账")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 · HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 预览
#Preview("Live Activity", as: .content, using: BillScanAttributes(activityId: "preview")) {
    BillScanLiveActivity()
} contentStates: {
    BillScanAttributes.ContentState(
        merchantName: "德园闽肠粉·蚝油捞·炖汤",
        amount: 63.30,
        timestamp: Date(),
        category: "餐饮",
        items: [
            .init(name: "闽肠粉", price: 15.30, quantity: 1),
            .init(name: "蚝油捞面", price: 36.00, quantity: 2),
            .init(name: "炖汤", price: 12.00, quantity: 1)
        ],
        billId: "preview-001"
    )
}
