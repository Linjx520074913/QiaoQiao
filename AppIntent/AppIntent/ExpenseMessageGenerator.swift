//
//  ExpenseMessageGenerator.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import Foundation

struct ExpenseMessageGenerator {
    /// 根据商家、金额、时间生成适合 Live Activity 显示的文本
    /// - Parameters:
    ///   - merchant: 商家名称
    ///   - amount: 消费金额
    ///   - time: 消费时间（可选）
    /// - Returns: 格式化的消费提醒文本
    static func generate(merchant: String, amount: Double, time: String?) -> String {
        let amountStr = String(format: "%.2f", amount)

        // 生成简洁友好的文本，适合一行显示
        let templates = [
            "在\(merchant)消费¥\(amountStr)",
            "\(merchant) ¥\(amountStr)",
            "刚在\(merchant)花了¥\(amountStr)",
            "\(merchant)消费提醒 ¥\(amountStr)"
        ]

        // 根据商家名长度选择合适的模板
        if merchant.count <= 4 {
            return templates[0] // "在XX消费¥XX"
        } else if merchant.count <= 6 {
            return templates[1] // "XXXX ¥XX"
        } else {
            return templates[1] // 较长商家名也使用简洁格式
        }
    }

    /// 生成带时间的详细文本（用于扩展视图）
    static func generateDetailed(merchant: String, amount: Double, time: String?) -> String {
        let amountStr = String(format: "%.2f", amount)

        if let time = time, !time.isEmpty {
            return "\(time) 在\(merchant)消费¥\(amountStr)"
        } else {
            return "在\(merchant)消费¥\(amountStr)"
        }
    }
}
