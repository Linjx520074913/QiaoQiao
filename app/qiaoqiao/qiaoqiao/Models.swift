//
//  Models.swift
//  qiaoqiao
//
//  数据模型
//

import Foundation

// MARK: - 账单明细项
struct InvoiceItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let quantity: Double?
    let unitPrice: Double?
    let amount: Double?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case unitPrice = "unit_price"
        case amount
        case description
    }

    init(id: UUID = UUID(), name: String, quantity: Double? = nil, unitPrice: Double? = nil, amount: Double? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.amount = amount
        self.description = description
    }

    // 从 Decoder 解码时，如果没有 id 则自动生成
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.quantity = try? container.decode(Double.self, forKey: .quantity)
        self.unitPrice = try? container.decode(Double.self, forKey: .unitPrice)
        self.amount = try? container.decode(Double.self, forKey: .amount)
        self.description = try? container.decode(String.self, forKey: .description)
    }
}

// MARK: - 账单信息
struct Invoice: Codable {
    let invoiceType: String?
    let invoiceNumber: String?
    let invoiceDate: String?
    let sellerName: String?
    let buyerName: String?
    let buyerPhone: String?
    let totalAmount: Double?
    let items: [InvoiceItem]?
    let remarks: String?

    enum CodingKeys: String, CodingKey {
        case invoiceType = "invoice_type"
        case invoiceNumber = "invoice_number"
        case invoiceDate = "invoice_date"
        case sellerName = "seller_name"
        case buyerName = "buyer_name"
        case buyerPhone = "buyer_phone"
        case totalAmount = "total_amount"
        case items
        case remarks
    }
}

// MARK: - 扫描结果
struct ScanResult: Codable {
    let success: Bool
    let data: ScanData?
    let error: String?
    let performance: [String: Double]?
}

struct ScanData: Codable {
    let type: String?
    let invoice: Invoice?
    let stats: [String: Int]?
    let orders: [OrderResult]?
}

struct OrderResult: Codable {
    let success: Bool
    let invoice: Invoice?
    let error: String?
}

// MARK: - 记账记录
struct BillRecord: Identifiable, Codable {
    let id: UUID
    let invoice: Invoice
    let image: Data?  // 存储图片数据
    let createdAt: Date
    let scanPerformance: [String: Double]?

    init(id: UUID = UUID(), invoice: Invoice, image: Data? = nil, createdAt: Date = Date(), scanPerformance: [String: Double]? = nil) {
        self.id = id
        self.invoice = invoice
        self.image = image
        self.createdAt = createdAt
        self.scanPerformance = scanPerformance
    }
}
