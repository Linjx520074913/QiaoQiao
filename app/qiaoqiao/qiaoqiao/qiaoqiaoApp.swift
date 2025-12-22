//
//  qiaoqiaoApp.swift
//  qiaoqiao
//
//  Created by linjx on 2025/12/18.
//

import SwiftUI

@main
struct qiaoqiaoApp: App {
    @StateObject private var appState = AppStateManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // MARK: - Deep Link 处理
    private func handleDeepLink(_ url: URL) {
        print("📱 收到 Deep Link: \(url)")

        // 解析 URL: kapi://confirm-bill?id=xxx
        guard url.scheme == "kapi" else { return }

        if url.host == "confirm-bill" {
            // 获取账单 ID
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let billId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                print("✅ 确认账单 ID: \(billId)")

                // 触发显示账单确认页
                appState.showBillFromLiveActivity(billId: billId)

                // 结束 Live Activity
                if #available(iOS 16.2, *) {
                    LiveActivityManager.shared.endCurrentActivity()
                }
            }
        }
    }
}

// MARK: - 根视图（控制启动路由）
struct RootView: View {
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        ZStack {
            // 主页面
            ContentView()

            // 待确认账单页（如果存在）
            if appState.showBillConfirmation, let bill = appState.pendingBill {
                BillConfirmationView(
                    bill: bill,
                    onConfirm: {
                        // 确认入账
                        appState.confirmBill()
                    },
                    onEdit: {
                        // 编辑账单
                        print("📝 编辑账单")
                        // TODO: 跳转到编辑页
                        appState.clearPendingBill()
                    }
                )
                .transition(.identity)
                .zIndex(999)
            }
        }
    }
}
