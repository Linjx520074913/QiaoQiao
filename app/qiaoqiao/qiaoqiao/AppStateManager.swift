//
//  AppStateManager.swift
//  qiaoqiao
//
//  App 状态管理 - 控制启动路由
//

import Foundation
import SwiftUI

// MARK: - App 状态管理器
@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    // 待确认账单
    @Published var pendingBill: PendingBill? = nil

    // 是否显示确认页
    @Published var showBillConfirmation: Bool = false

    private init() {
        loadPendingBill()
    }

    // MARK: - 加载待确认账单
    func loadPendingBill() {
        // 从 UserDefaults 加载
        if let data = UserDefaults.standard.data(forKey: "pendingBill"),
           let bill = try? JSONDecoder().decode(PendingBill.self, from: data) {
            self.pendingBill = bill
            self.showBillConfirmation = true
            print("📱 加载到待确认账单: \(bill.merchantName) ¥\(bill.amount)")
        }
    }

    // MARK: - 保存待确认账单
    func savePendingBill(_ bill: PendingBill) {
        self.pendingBill = bill
        self.showBillConfirmation = true

        // 持久化到 UserDefaults
        if let data = try? JSONEncoder().encode(bill) {
            UserDefaults.standard.set(data, forKey: "pendingBill")
            print("💾 保存待确认账单: \(bill.merchantName) ¥\(bill.amount)")
        }
    }

    // MARK: - 确认账单
    func confirmBill() {
        guard let bill = pendingBill else { return }

        print("✅ 确认入账: \(bill.merchantName) ¥\(bill.amount)")

        // TODO: 这里调用实际的记账逻辑
        // BillManager.shared.addRecord(...)

        // 清除待确认账单
        clearPendingBill()
    }

    // MARK: - 清除待确认账单
    func clearPendingBill() {
        self.pendingBill = nil
        self.showBillConfirmation = false
        UserDefaults.standard.removeObject(forKey: "pendingBill")
        print("🗑️ 清除待确认账单")
    }

    // MARK: - 从 Live Activity 显示账单
    func showBillFromLiveActivity(billId: String) {
        // 从持久化存储中查找账单
        if let data = UserDefaults.standard.data(forKey: "pendingBill_\(billId)"),
           let bill = try? JSONDecoder().decode(PendingBill.self, from: data) {
            self.pendingBill = bill
            self.showBillConfirmation = true
            print("📱 从 Live Activity 加载账单: \(bill.merchantName) ¥\(bill.amount)")
        } else {
            // 如果没有找到，尝试加载默认的待确认账单
            loadPendingBill()
        }
    }

    // MARK: - 模拟创建待确认账单（用于测试）
    func createMockPendingBill() {
        let mockBill = PendingBill(
            merchantName: "星巴克咖啡",
            amount: 45.00,
            timestamp: Date(),
            category: "餐饮"
        )
        savePendingBill(mockBill)
    }
}
