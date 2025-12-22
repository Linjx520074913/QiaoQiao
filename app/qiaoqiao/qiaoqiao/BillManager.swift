//
//  BillManager.swift
//  qiaoqiao
//
//  记账记录管理器
//

import Foundation
import Combine

class BillManager: ObservableObject {
    static let shared = BillManager()

    @Published var records: [BillRecord] = []

    private let userDefaultsKey = "bill_records"

    private init() {
        loadRecords()
    }

    // MARK: - 数据操作

    /// 添加记账记录
    func addRecord(_ record: BillRecord) {
        records.insert(record, at: 0)  // 新记录插入到最前面
        saveRecords()
    }

    /// 删除记账记录
    func deleteRecord(_ record: BillRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }

    /// 删除多条记录
    func deleteRecords(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        saveRecords()
    }

    /// 清空所有记录
    func clearAll() {
        records.removeAll()
        saveRecords()
    }

    // MARK: - 持久化

    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("❌ 保存记录失败: \(error)")
        }
    }

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            records = try JSONDecoder().decode([BillRecord].self, from: data)
            print("✅ 加载了 \(records.count) 条记录")
        } catch {
            print("❌ 加载记录失败: \(error)")
        }
    }

    // MARK: - 统计

    /// 计算总支出
    var totalExpense: Double {
        records.reduce(0) { $0 + ($1.invoice.totalAmount ?? 0) }
    }

    /// 按商家统计
    func expenseByMerchant() -> [(merchant: String, amount: Double)] {
        var dict: [String: Double] = [:]

        for record in records {
            let merchant = record.invoice.sellerName ?? "未知商家"
            dict[merchant, default: 0] += record.invoice.totalAmount ?? 0
        }

        return dict.map { (merchant: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    /// 按日期统计
    func expenseByDate() -> [(date: String, amount: Double)] {
        var dict: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for record in records {
            let dateStr = formatter.string(from: record.createdAt)
            dict[dateStr, default: 0] += record.invoice.totalAmount ?? 0
        }

        return dict.map { (date: $0.key, amount: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
