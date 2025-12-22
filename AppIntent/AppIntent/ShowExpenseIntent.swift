//
//  ShowExpenseIntent.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import AppIntents
import SwiftUI

struct ShowExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "显示消费卡片"
    static var description = IntentDescription("在主屏幕顶部显示消费提醒卡片")

    // 关键：设置为后台运行，不打开应用
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // 使用固定的测试数据
        let merchant = "星巴克"
        let amount = 80.0

        let messageText = ExpenseMessageGenerator.generate(
            merchant: merchant,
            amount: amount,
            time: nil
        )

        // 返回带自定义视图的结果
        return .result(
            dialog: IntentDialog(stringLiteral: messageText),
            view: ExpenseSnippetView(merchant: merchant, amount: amount)
        )
    }
}

// 自定义卡片视图
struct ExpenseSnippetView: View {
    let merchant: String
    let amount: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(merchant)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("消费提醒")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("¥\(String(format: "%.2f", amount))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
