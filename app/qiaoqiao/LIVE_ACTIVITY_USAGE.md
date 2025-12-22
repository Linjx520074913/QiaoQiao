# Live Activity 桌面卡片使用指南

## 功能说明

当用户扫描账单后，系统会在**手机桌面**（锁屏或灵动岛）上显示一个账单确认卡片，用户可以直接在桌面上查看账单信息并点击「记账」按钮进入 App 确认。

## 效果展示

类似图片中的效果：
- 显示商家名称、时间、总金额
- 显示账单明细（前3项）
- 底部有橙色「记账」按钮
- 点击按钮直接进入 App 的账单确认页

## 使用方法

### 1. 在扫描完成后启动 Live Activity

```swift
import SwiftUI

// 在扫描结果处理函数中
func handleScanResult(invoice: InvoiceData) {
    // 创建待确认账单
    let pendingBill = LiveActivityManager.createPendingBill(from: invoice)

    // 创建账单明细项
    let billItems = LiveActivityManager.createBillItems(from: invoice)

    // 保存账单数据到持久化存储（用于后续深度链接）
    if let data = try? JSONEncoder().encode(pendingBill) {
        UserDefaults.standard.set(data, forKey: "pendingBill_\(pendingBill.id)")
    }

    // 启动 Live Activity
    if #available(iOS 16.2, *) {
        LiveActivityManager.shared.startActivity(from: pendingBill, items: billItems)
    }
}
```

### 2. 测试代码（模拟扫描结果）

```swift
// 在 ContentView 或测试页面中添加按钮
Button("测试 Live Activity") {
    testLiveActivity()
}

func testLiveActivity() {
    // 创建模拟账单
    let mockBill = PendingBill(
        id: UUID().uuidString,
        merchantName: "德园闽肠粉·蚝油捞·炖汤",
        amount: 63.30,
        timestamp: Date(),
        category: "餐饮"
    )

    // 创建模拟账单明细
    let mockItems: [BillScanAttributes.ContentState.BillItem] = [
        .init(name: "闽肠粉", price: 15.30, quantity: 1),
        .init(name: "蚝油捞面", price: 36.00, quantity: 2),
        .init(name: "炖汤", price: 12.00, quantity: 1)
    ]

    // 保存到持久化存储
    if let data = try? JSONEncoder().encode(mockBill) {
        UserDefaults.standard.set(data, forKey: "pendingBill_\(mockBill.id)")
    }

    // 启动 Live Activity
    if #available(iOS 16.2, *) {
        LiveActivityManager.shared.startActivity(from: mockBill, items: mockItems)
    }
}
```

## 交互流程

1. **扫描账单** → 后端识别成功
2. **启动 Live Activity** → 桌面显示账单卡片
3. **用户查看** → 在桌面直接查看账单信息
4. **点击「记账」** → 触发 Deep Link 打开 App
5. **进入确认页** → 显示完整账单信息
6. **确认入账** → 记录到账单列表，结束 Live Activity

## 所需权限

在 Xcode 项目配置中：

### 1. Info.plist 添加 URL Scheme
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kapi</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.qiaoqiao</string>
    </dict>
</array>
```

### 2. 启用 Live Activity 权限
在 **Signing & Capabilities** → **Background Modes** 中勾选：
- ✅ Push Notifications (用于 Live Activity)

### 3. Info.plist 添加 Live Activity 支持
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

## 注意事项

1. **iOS 版本要求**：Live Activity 需要 iOS 16.2+
2. **用户权限**：用户需要在设置中允许 Live Activity
3. **时效性**：Live Activity 最多显示 8 小时，超时会自动消失
4. **测试方法**：
   - 真机测试（模拟器不支持 Live Activity）
   - 或使用 Xcode Preview 预览 UI

## 文件清单

- ✅ `BillScanAttributes.swift` - Live Activity 数据模型
- ✅ `BillScanLiveActivity.swift` - Live Activity UI
- ✅ `ScanBillIntent.swift` - App Intent（记账按钮）
- ✅ `LiveActivityManager.swift` - Live Activity 管理器
- ✅ `qiaoqiaoApp.swift` - Deep Link 处理
- ✅ `AppStateManager.swift` - App 状态管理

## 下一步

1. 在真机上测试 Live Activity
2. 集成到实际的扫描流程中
3. 优化 UI 细节（图标、动画等）
4. 添加错误处理和重试机制
