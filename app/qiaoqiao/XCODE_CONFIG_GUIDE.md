# Xcode 项目配置指南 - Live Activity

## 必需配置步骤

### 1. 配置 URL Scheme（Deep Link）

**位置**：选择主 App Target → Info 标签页

添加以下配置到 `Info.plist`：

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

**快捷方式（推荐）**：
1. 打开 Xcode
2. 选择 `qiaoqiao` Target
3. 点击 **Info** 标签页
4. 找到 **URL Types** 部分，点击 **+** 添加：
   - **Identifier**: `com.yourcompany.qiaoqiao`
   - **URL Schemes**: `kapi`

### 2. 启用 Live Activity 支持

**方法1：通过 Info.plist**

在主 App 的 `Info.plist` 中添加：

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**方法2：通过 Xcode UI**
1. 选择主 App Target → Info
2. 右键点击列表空白处 → **Add Row**
3. 输入 `NSSupportsLiveActivities`
4. 类型选择 **Boolean**，值设为 **YES**

### 3. 配置 Widget Extension

确保 `BillScanWidget` Extension 已正确配置：

1. **Target**: `BillScanWidget`
2. **Bundle Identifier**: `com.yourcompany.qiaoqiao.BillScanWidget`
3. **Deployment Target**: iOS 16.2+（Live Activity 最低要求）

### 4. 配置 App Groups（用于数据共享）

**主 App 和 Widget Extension 都需要配置**：

1. 选择 Target → **Signing & Capabilities**
2. 点击 **+ Capability**
3. 添加 **App Groups**
4. 点击 **+** 添加 Group：
   - 格式：`group.com.yourcompany.qiaoqiao`

**注意**：主 App 和 Widget Extension 必须使用相同的 App Group ID。

### 5. 配置推送通知（可选，Live Activity需要）

虽然 Live Activity 不直接使用推送，但需要推送权限：

1. 选择主 App Target → **Signing & Capabilities**
2. 点击 **+ Capability**
3. 添加 **Push Notifications**

## 项目文件检查清单

### 主 App（qiaoqiao）
- ✅ `qiaoqiaoApp.swift` - 包含 Deep Link 处理
- ✅ `AppStateManager.swift` - 状态管理
- ✅ `LiveActivityManager.swift` - Live Activity 管理器
- ✅ `PendingBill.swift` - 数据模型
- ✅ `BillConfirmationView.swift` - 确认页面

### Widget Extension（BillScanWidget）
- ✅ `BillScanAttributes.swift` - Live Activity 数据模型
- ✅ `BillScanLiveActivity.swift` - UI 视图
- ✅ `ScanBillIntent.swift` - App Intents
- ✅ `BillScanWidgetBundle.swift` - Widget 入口

## 测试步骤

### 1. 在真机上测试（Live Activity 不支持模拟器）

1. 连接 iPhone（iOS 16.2+）
2. 在 Xcode 选择真机设备
3. 运行主 App
4. 点击「测试：桌面Live Activity」按钮
5. **退出 App 或锁屏**，查看桌面是否显示卡片

### 2. 查看 Live Activity

Live Activity 会显示在：
- 锁屏界面
- 通知中心
- 灵动岛（iPhone 14 Pro 及以上）

### 3. 测试按钮交互

1. 在桌面卡片上点击「记账」按钮
2. App 应该自动打开并显示账单确认页
3. Live Activity 应该自动消失

## 常见问题

### Q: 点击测试按钮后没有显示 Live Activity？

**可能原因**：
1. 设备版本不是 iOS 16.2+
2. Live Activity 权限未开启
   - 设置 → 通知 → qiaoqiao → 允许实时活动
3. 使用的是模拟器（Live Activity 仅支持真机）

**解决方案**：
```swift
// 检查权限
if #available(iOS 16.2, *) {
    let authInfo = ActivityAuthorizationInfo()
    print("Live Activity 权限: \(authInfo.areActivitiesEnabled)")
}
```

### Q: Live Activity 显示了但点击按钮没反应？

**可能原因**：
- URL Scheme 未正确配置
- Deep Link 处理代码有误

**解决方案**：
1. 检查 Info.plist 中的 URL Scheme 配置
2. 在控制台查看是否有 "📱 收到 Deep Link" 日志
3. 确认 `handleDeepLink` 方法正确实现

### Q: 编译错误：找不到 ActivityKit？

**解决方案**：
```swift
// 确保导入了 ActivityKit
import ActivityKit

// 使用版本检查
if #available(iOS 16.2, *) {
    // Live Activity 代码
}
```

### Q: Widget Extension 编译失败？

**可能原因**：
- Deployment Target 低于 iOS 16.2
- Bundle Identifier 冲突

**解决方案**：
1. 检查 Widget Target 的 Deployment Target >= iOS 16.2
2. 确保 Bundle ID 格式：`主App.BillScanWidget`

## 下一步优化

1. **添加动画和过渡效果**
2. **支持多个 Live Activity**（多张账单同时显示）
3. **添加编辑按钮**（在 Live Activity 上直接编辑）
4. **优化 UI**（根据实际需求调整颜色、字体等）
5. **错误处理**（网络失败、识别失败等）
6. **集成到实际扫描流程**

## 参考资料

- [Apple - ActivityKit 官方文档](https://developer.apple.com/documentation/activitykit)
- [Apple - Live Activities 设计指南](https://developer.apple.com/design/human-interface-guidelines/live-activities)
- [Apple - App Intents 文档](https://developer.apple.com/documentation/appintents)
