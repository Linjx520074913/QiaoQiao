//
//  BillScanAttributes.swift
//  BillScanWidget
//
//  Live Activity 数据定义
//

import Foundation
import ActivityKit

// MARK: - Live Activity Attributes（不变的属性）
struct BillScanAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 账单信息
        var merchantName: String
        var amount: Double
        var timestamp: Date
        var category: String?
        var items: [BillItem]?
        var billId: String

        struct BillItem: Codable, Hashable {
            var name: String
            var price: Double
            var quantity: Int?
        }
    }

    // 固定属性：Activity ID
    var activityId: String
}
