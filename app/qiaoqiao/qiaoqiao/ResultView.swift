//
//  ResultView.swift
//  qiaoqiao
//
//  识别结果展示页面 - 全屏悬浮卡片
//

import SwiftUI

struct ResultView: View {
    let scanResult: ScanResult
    let image: UIImage

    @ObservedObject var billManager = BillManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showingSaveAlert = false
    @State private var isSaved = false

    var body: some View {
        ZStack {
            // 半透明遮罩层（点击可关闭）
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // 账单卡片（全屏悬浮）
            if let data = scanResult.data, let invoice = data.invoice {
                let imageData = image.jpegData(compressionQuality: 0.8)
                let record = BillRecord(
                    invoice: invoice,
                    image: imageData,
                    scanPerformance: scanResult.performance
                )

                BillCardView(record: record, backgroundColor: Color(.systemGroupedBackground)) {
                    // 记账按钮点击
                    saveRecord(record)
                }
                .padding(20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("保存成功", isPresented: $showingSaveAlert) {
            Button("查看记账") {
                dismiss()
            }
            Button("继续扫描", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("账单已保存到记账列表")
        }
    }

    // MARK: - 保存记录
    private func saveRecord(_ record: BillRecord) {
        withAnimation {
            billManager.addRecord(record)
            isSaved = true
            showingSaveAlert = true
        }
    }
}

// MARK: - 性能统计卡片
struct PerformanceCard: View {
    let performance: [String: Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性能统计")
                .font(.headline)

            HStack(spacing: 20) {
                if let total = performance["total"] {
                    StatItem(label: "总耗时", value: String(format: "%.2fs", total), color: .blue)
                }
                if let ocr = performance["ocr"] {
                    StatItem(label: "OCR", value: String(format: "%.2fs", ocr), color: .green)
                }
                if let parse = performance["parse"] {
                    StatItem(label: "解析", value: String(format: "%.2fs", parse), color: .purple)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 预览
struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        let invoice = Invoice(
            invoiceType: "外卖订单",
            invoiceNumber: "1234567890",
            invoiceDate: "2025-12-18 12:00:00",
            sellerName: "德园闽肠粉·蚝油捞·炖汤（西丽店）",
            buyerName: nil,
            buyerPhone: nil,
            totalAmount: 15.30,
            items: [
                InvoiceItem(name: "闽肠粉", quantity: 1, unitPrice: 15.30, amount: 15.30, description: nil)
            ],
            remarks: nil
        )

        let scanData = ScanData(
            type: "single_order",
            invoice: invoice,
            stats: nil,
            orders: nil
        )

        let scanResult = ScanResult(
            success: true,
            data: scanData,
            error: nil,
            performance: ["total": 2.5, "ocr": 0.8, "parse": 1.7]
        )

        NavigationStack {
            ResultView(
                scanResult: scanResult,
                image: UIImage(systemName: "photo")!
            )
        }
    }
}
