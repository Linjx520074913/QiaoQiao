//
//  ExpenseActivityView.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct ExpenseActivityView: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExpenseActivityAttributes.self) { context in
            // Lock screen/banner UI
            ExpenseLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("¥\(String(format: "%.2f", context.state.amount))")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.merchant)
                        .font(.caption)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("¥\(String(format: "%.0f", context.state.amount))")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                Image(systemName: "creditcard.fill")
            }
        }
    }
}

@available(iOS 16.1, *)
struct ExpenseLiveActivityView: View {
    let context: ActivityViewContext<ExpenseActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.title3)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.message)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let time = context.state.time, !time.isEmpty {
                    Text(time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text("¥\(String(format: "%.2f", context.state.amount))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(Color(white: 0.95))
        .activitySystemActionForegroundColor(.black)
    }
}
