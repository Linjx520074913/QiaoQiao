//
//  ScanBillIntent.swift
//  BillScanWidget
//
//  快捷指令 Intent 定义
//

import Foundation
import AppIntents
import ActivityKit
import UIKit

// MARK: - 识别账单 Intent
struct ScanBillIntent: AppIntent {
    static var title: LocalizedStringResource = "识别账单"
    static var description = IntentDescription("使用 KAPI 识别账单图片")

    // 输入参数：图片
    @Parameter(title: "账单图片")
    var image: IntentFile?

    // 执行方法
    func perform() async throws -> some IntentResult {
        print("🚀 ScanBillIntent 开始执行")

        // 第1步：立即启动 Live Activity
        let activityId = UUID().uuidString
        print("📱 准备启动 Live Activity, ID: \(activityId)")

        do {
            let initialState = BillScanAttributes.ContentState(
                message: "Hello World!",
                timestamp: Date()
            )

            let activity = try Activity.request(
                attributes: BillScanAttributes(activityId: activityId),
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            print("✅ Live Activity 启动成功!")
            print("📊 Activity ID: \(activity.id)")

            // 第2步：等待 5 秒（模拟识别过程）
            try await Task.sleep(nanoseconds: 5_000_000_000)

            // 第3步：更新 Live Activity
            let updatedState = BillScanAttributes.ContentState(
                message: "识别完成！测试成功",
                timestamp: Date()
            )

            await activity.update(
                .init(state: updatedState, staleDate: nil)
            )

            print("🔄 Live Activity 更新成功!")

        } catch {
            print("❌ Live Activity 启动失败: \(error.localizedDescription)")
            throw error
        }

        return .result(dialog: "账单识别完成")
    }
}

// MARK: - 确认记账 Intent
struct ConfirmBillIntent: AppIntent {
    static var title: LocalizedStringResource = "确认记账"
    static var description = IntentDescription("确认并记录账单")

    @Parameter(title: "账单ID")
    var billId: String

    func perform() async throws -> some IntentResult {
        print("✅ 确认记账 Intent 执行, billId: \(billId)")

        // 打开主 App 并传递账单 ID
        if let url = URL(string: "kapi://confirm-bill?id=\(billId)") {
            await UIApplication.shared.open(url)
        }

        return .result()
    }
}

// MARK: - App Intents Extension
struct BillScanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanBillIntent(),
            phrases: [
                "识别账单",
                "扫描账单",
                "KAPI识别"
            ],
            shortTitle: "识别账单",
            systemImageName: "doc.text.magnifyingglass"
        )
    }
}
