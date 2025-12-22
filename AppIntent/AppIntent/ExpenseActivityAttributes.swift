//
//  ExpenseActivityAttributes.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import ActivityKit
import Foundation

struct ExpenseActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var merchant: String
        var amount: Double
        var time: String?
        var message: String
    }

    var id: String
}
