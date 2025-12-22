import SwiftUI

struct BillCardView: View {

    let record: BillRecord
    let backgroundColor: Color
    let onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var dividerY: CGFloat = 200  // 初始值设为合理位置

    init(
        record: BillRecord,
        backgroundColor: Color = Color(.systemGroupedBackground),
        onSave: (() -> Void)? = nil
    ) {
        self.record = record
        self.backgroundColor = backgroundColor
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: 顶部导航
            HStack {
                Button("‹") { dismiss() }
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)

                Spacer()

                Text("扫描完成")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button("✕") { dismiss() }
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .frame(height: 52)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "#f0f0f0"))
                    .frame(height: 1),
                alignment: .bottom
            )

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: 商家信息
                    VStack(spacing: 12) {
                        Text("☕")
                            .font(.system(size: 28))
                            .frame(width: 64, height: 64)
                            .background(Color(hex: "#00704A"))
                            .clipShape(Circle())

                        Text(record.invoice.sellerName ?? "未知商家")
                            .font(.system(size: 18, weight: .semibold))

                        if let date = record.invoice.invoiceDate {
                            Text(formatDate(date))
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8e8e93"))
                        }
                    }
                    .padding(.vertical, 24)

                    // MARK: 总金额
                    HStack {
                        Text("总金额")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Text("¥\(String(format: "%.2f", record.invoice.totalAmount ?? 0))")
                            .font(.system(size: 22, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // MARK: 虚线分割（记录缺口 Y）
                    ZStack {
                        // 虚线
                        GeometryReader { geo in
                            Path { path in
                                path.move(to: CGPoint(x: 20, y: 0))
                                path.addLine(to: CGPoint(x: geo.size.width - 20, y: 0))
                            }
                            .stroke(
                                Color(hex: "#e0e0e0"),
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                            )
                        }
                        .frame(height: 1)

                        // 坐标捕获层
                        GeometryReader { geo in
                            let localY = geo.frame(in: .local).midY
                            let globalY = geo.frame(in: .named("cardContainer")).midY

                            Color.clear
                                .onAppear {
                                    print("🔍 虚线 local Y: \(localY)")
                                    print("🔍 虚线 global Y (cardContainer): \(globalY)")
                                }
                                .preference(
                                    key: DividerYPreferenceKey.self,
                                    value: globalY
                                )
                        }
                        .frame(height: 1)
                    }
                    .padding(.vertical, 24)

                    // MARK: 条形码
                    VStack(spacing: 12) {
                        BarcodeView()
                            .frame(width: 200, height: 60)

                        Text("THANK YOU!")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.bottom, 24)
                }
            }

            // MARK: 底部按钮
            Button(action: { onSave?() }) {
                Text("记账")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "#FF9500"))
                    .cornerRadius(26)
            }
            .padding(20)
        }
        .background(
            GeometryReader { geo in
                Color.white
                    .onAppear {
                        // 调试输出卡片总高度
                        print("📐 卡片总高度: \(geo.size.height)")
                    }
            }
        )
        .coordinateSpace(name: "cardContainer")  // 坐标空间定义在这里
        .clipShape(
            TicketCardShape(
                notchY: dividerY,
                notchRadius: 10
            )
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 2)
        .onPreferenceChange(DividerYPreferenceKey.self) { value in
            print("📏 虚线位置 Y: \(value)")
            dividerY = value
        }
    }

    private func formatDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: " ")
        guard parts.count >= 2 else { return dateStr }
        let date = parts[0].split(separator: "-")
        let time = parts[1].prefix(5)
        guard date.count == 3 else { return dateStr }
        return "\(date[0])年\(date[1])月\(date[2])日 · \(time)"
    }
}

// MARK: - PreferenceKey for Divider Position
struct DividerYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - 真缺口 Shape
struct TicketCardShape: Shape {
    var notchY: CGFloat
    let notchRadius: CGFloat

    var animatableData: CGFloat {
        get { notchY }
        set { notchY = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius: CGFloat = 16

        // 调试输出
        print("🎨 Shape: rect.height = \(rect.height), notchY = \(notchY)")

        // 边界保护：确保缺口不与圆角相交
        let safeNotchY = max(
            cornerRadius + notchRadius + 10,
            min(notchY, rect.height - cornerRadius - notchRadius - 10)
        )

        print("🎨 Shape: safeNotchY = \(safeNotchY)")

        // 从左上角开始，顺时针绘制完整轮廓

        // 1. 左上圆角（从左边中点开始）
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        // 2. 顶部边
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))

        // 3. 右上圆角
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )

        // 4. 右侧边（到缺口上方）
        path.addLine(to: CGPoint(x: rect.width, y: safeNotchY - notchRadius))

        // 5. 右侧缺口（向内凹的半圆）
        // 圆心在右边界上，从 -90° 到 90°，逆时针绘制（向左凹进）
        path.addArc(
            center: CGPoint(x: rect.width, y: safeNotchY),
            radius: notchRadius,
            startAngle: .degrees(270),  // -90° (顶部)
            endAngle: .degrees(90),     // 90° (底部)
            clockwise: true  // 顺时针绕行 = 向内凹
        )

        // 6. 右侧边（缺口下方到右下圆角）
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // 7. 右下圆角
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // 8. 底部边
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        // 9. 左下圆角
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // 10. 左侧边（到缺口下方）
        path.addLine(to: CGPoint(x: 0, y: safeNotchY + notchRadius))

        // 11. 左侧缺口（向内凹的半圆）
        // 圆心在左边界上，从 90° 到 -90°（即270°），逆时针绘制（向右凹进）
        path.addArc(
            center: CGPoint(x: 0, y: safeNotchY),
            radius: notchRadius,
            startAngle: .degrees(90),   // 90° (底部)
            endAngle: .degrees(270),    // 270° (顶部)
            clockwise: true  // 顺时针绕行 = 向内凹
        )

        // 12. 左侧边（缺口上方回到起点）
        path.closeSubpath()

        return path
    }
}

// MARK: - 条形码
struct BarcodeView: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<30, id: \.self) { i in
                Rectangle()
                    .fill(i % 2 == 0 ? Color.black : Color.clear)
                    .frame(width: i % 3 == 0 ? 4 : 2)
            }
        }
        .cornerRadius(4)
    }
}

// MARK: - Color Hex 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
