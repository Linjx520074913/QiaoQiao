//
//  ExpenseActivityManager.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
class ExpenseActivityManager {
    static let shared = ExpenseActivityManager()

    private var currentActivity: Activity<ExpenseActivityAttributes>?

    private init() {}

    func startActivity(merchant: String, amount: Double, time: String?, message: String) async throws {
        // 如果已有活动，先结束
        if let activity = currentActivity {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let attributes = ExpenseActivityAttributes(id: UUID().uuidString)
        let contentState = ExpenseActivityAttributes.ContentState(
            merchant: merchant,
            amount: amount,
            time: time,
            message: message
        )

        do {
            // 设置自动消失时间（30秒后）
            let futureDate = Calendar.current.date(byAdding: .second, value: 30, to: Date())

            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: futureDate),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            throw error
        }
    }

    func updateActivity(merchant: String, amount: Double, time: String?, message: String) async {
        guard let activity = currentActivity else { return }

        let contentState = ExpenseActivityAttributes.ContentState(
            merchant: merchant,
            amount: amount,
            time: time,
            message: message
        )

        // 更新 Live Activity 内容
        let futureDate = Calendar.current.date(byAdding: .second, value: 30, to: Date())
        await activity.update(
            ActivityContent(state: contentState, staleDate: futureDate)
        )
    }

    func endActivity() async {
        guard let activity = currentActivity else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
