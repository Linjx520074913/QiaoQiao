//
//  LiveActivityManager.swift
//  qiaoqiao
//
//  Live Activity 管理器 - 用于在桌面显示账单确认卡片
//

import Foundation
import ActivityKit
import SwiftUI

@available(iOS 16.2, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var currentActivity: Activity<BillScanAttributes>?

    private init() {}

    // MARK: - 启动 Live Activity（显示桌面卡片）

    /// 从待确认账单启动 Live Activity
    func startActivity(from bill: PendingBill, items: [BillScanAttributes.ContentState.BillItem]? = nil) {
        // 检查权限
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activity 权限未开启")
            return
        }

        // 如果已有活动，先结束
        endCurrentActivity()

        let attributes = BillScanAttributes(activityId: bill.id)
        let contentState = BillScanAttributes.ContentState(
            merchantName: bill.merchantName,
            amount: bill.amount,
            timestamp: bill.timestamp,
            category: bill.category,
            items: items,
            billId: bill.id
        )

        do {
            let activity = try Activity<BillScanAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity
            print("✅ Live Activity 已启动: \(activity.id)")

        } catch {
            print("❌ 启动 Live Activity 失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 更新 Live Activity

    func updateActivity(merchantName: String? = nil, amount: Double? = nil, items: [BillScanAttributes.ContentState.BillItem]? = nil) {
        guard let activity = currentActivity else {
            print("⚠️ 没有活动的 Live Activity")
            return
        }

        Task {
            var newState = activity.content.state

            if let merchantName = merchantName {
                newState.merchantName = merchantName
            }
            if let amount = amount {
                newState.amount = amount
            }
            if let items = items {
                newState.items = items
            }

            await activity.update(
                .init(state: newState, staleDate: nil)
            )

            print("✅ Live Activity 已更新")
        }
    }

    // MARK: - 结束 Live Activity

    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(
                .init(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )

            print("✅ Live Activity 已结束")
            currentActivity = nil
        }
    }

    // MARK: - 辅助方法

    /// 从扫描结果创建 BillItem 数组
    static func createBillItems(from invoice: InvoiceData) -> [BillScanAttributes.ContentState.BillItem] {
        guard let items = invoice.items, !items.isEmpty else {
            return []
        }

        return items.map { item in
            BillScanAttributes.ContentState.BillItem(
                name: item.name ?? "未知项目",
                price: item.amount ?? 0,
                quantity: item.quantity
            )
        }
    }

    /// 从发票数据创建 PendingBill
    static func createPendingBill(from invoice: InvoiceData) -> PendingBill {
        return PendingBill(
            merchantName: invoice.sellerName ?? "未知商家",
            amount: invoice.totalAmount ?? 0,
            timestamp: Date(),
            category: invoice.category
        )
    }
}
