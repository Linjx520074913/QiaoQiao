//
//  BillListView.swift
//  qiaoqiao
//
//  记账列表页面
//

import SwiftUI

struct BillListView: View {
    @ObservedObject var billManager = BillManager.shared

    @State private var showingStats = false

    var body: some View {
        NavigationStack {
            ZStack {
                if billManager.records.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("还没有记账记录")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text("扫描账单后点击记账即可添加")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 记录列表
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // 统计卡片
                            StatsSummaryCard(
                                totalExpense: billManager.totalExpense,
                                recordCount: billManager.records.count
                            )
                            .padding(.horizontal)
                            .onTapGesture {
                                showingStats = true
                            }

                            // 记录列表
                            ForEach(billManager.records) { record in
                                BillCardView(record: record)
                                    .padding(.horizontal)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                billManager.deleteRecord(record)
                                            }
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("我的记账")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !billManager.records.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingStats = true
                            } label: {
                                Label("统计", systemImage: "chart.bar")
                            }

                            Divider()

                            Button(role: .destructive) {
                                billManager.clearAll()
                            } label: {
                                Label("清空所有", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
        }
    }
}

// MARK: - 统计汇总卡片
struct StatsSummaryCard: View {
    let totalExpense: Double
    let recordCount: Int

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("总支出")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("¥\(String(format: "%.2f", totalExpense))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.orange)
            }

            Spacer()

            Divider()
                .frame(height: 40)

            VStack(alignment: .trailing, spacing: 8) {
                Text("记录数")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(recordCount)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 统计详情页
struct StatsView: View {
    @ObservedObject var billManager = BillManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("按商家统计") {
                    ForEach(billManager.expenseByMerchant(), id: \.merchant) { item in
                        HStack {
                            Text(item.merchant)
                            Spacer()
                            Text("¥\(String(format: "%.2f", item.amount))")
                                .foregroundColor(.orange)
                        }
                    }
                }

                Section("按日期统计") {
                    ForEach(billManager.expenseByDate(), id: \.date) { item in
                        HStack {
                            Text(item.date)
                            Spacer()
                            Text("¥\(String(format: "%.2f", item.amount))")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("支出统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 预览
struct BillListView_Previews: PreviewProvider {
    static var previews: some View {
        BillListView()
    }
}
