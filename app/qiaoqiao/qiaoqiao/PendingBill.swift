//
//  PendingBill.swift
//  qiaoqiao
//
//  待确认账单数据模型
//

import Foundation

// MARK: - 待确认账单
struct PendingBill: Codable, Identifiable {
    let id: String
    let merchantName: String
    let amount: Double
    let timestamp: Date
    let category: String?

    init(
        id: String = UUID().uuidString,
        merchantName: String,
        amount: Double,
        timestamp: Date = Date(),
        category: String? = nil
    ) {
        self.id = id
        self.merchantName = merchantName
        self.amount = amount
        self.timestamp = timestamp
        self.category = category
    }
}

// MARK: - 示例数据
extension PendingBill {
    static let mockExample = PendingBill(
        merchantName: "星巴克咖啡",
        amount: 45.00,
        timestamp: Date(),
        category: "餐饮"
    )
}
