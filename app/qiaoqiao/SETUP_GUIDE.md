# Live Activity + App Intent 配置指南

## 📦 已创建的文件

我已经为你创建了以下文件：

```
BillScanWidget/
├── BillScanAttributes.swift       # Live Activity 数据结构
├── BillScanLiveActivity.swift     # Live Activity UI
├── ScanBillIntent.swift            # App Intent (快捷指令)
├── BillScanWidgetBundle.swift      # Widget Extension 入口
└── Info.plist                      # Extension 配置
```

---

## 🛠️ Xcode 手动配置步骤

### 步骤 1：添加 Widget Extension Target

1. 打开 `qiaoqiao.xcodeproj`
2. **File** → **New** → **Target**
3. 选择 **iOS** → **Widget Extension**
4. 配置：
   - **Product Name**: `BillScanWidget`
   - **Language**: Swift
   - **Include Configuration Intent**: ❌ **取消勾选**
   - 点击 **Finish**
5. 弹出激活 Scheme 对话框，点击 **Activate**

---

### 步骤 2：删除自动生成的文件

Xcode 会自动生成一些模板文件，我们需要删除它们：

1. 在左侧 Project Navigator 中找到 `BillScanWidget` 文件夹
2. 删除以下文件（移到废纸篓）：
   - `BillScanWidget.swift`
   - `BillScanWidgetLiveActivity.swift`
   - `AppIntent.swift`
   - `BillScanWidgetBundle.swift`（如果存在）

---

### 步骤 3：将我创建的文件添加到项目

1. 在 Finder 中打开 `BillScanWidget` 文件夹
2. 将以下文件拖到 Xcode 的 `BillScanWidget` 组中：
   - `BillScanAttributes.swift`
   - `BillScanLiveActivity.swift`
   - `ScanBillIntent.swift`
   - `BillScanWidgetBundle.swift`

3. 在弹出的对话框中：
   - ✅ 勾选 **Copy items if needed**
   - ✅ 勾选 **BillScanWidget** Target
   - ❌ 取消勾选 **qiaoqiao** Target
   - 点击 **Add**

---

### 步骤 4：配置主 App（qiaoqiao）

#### 4.1 添加 Live Activity 支持

1. 选中 **qiaoqiao** Target
2. **Signing & Capabilities** 标签
3. 点击 **+ Capability**
4. 搜索并添加：**App Groups**（如果还没有）

#### 4.2 在主 App 中导入 ActivityKit

1. 在 `qiaoqiaoApp.swift` 或任意主 App 文件中添加：

```swift
import ActivityKit
```

2. 在 App 启动时请求 Live Activity 权限（可选）：

```swift
@main
struct qiaoqiaoApp: App {
    init() {
        // 请求 Live Activity 权限（iOS 16.1+）
        if #available(iOS 16.1, *) {
            Task {
                await ActivityAuthorizationInfo().areActivitiesEnabled
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

### 步骤 5：配置 Bundle Identifier

1. 选中 **BillScanWidget** Target
2. **General** 标签
3. 确保 **Bundle Identifier** 为：
   ```
   com.kapi.qiaoqiao.BillScanWidget
   ```
   （如果主 App 是 `com.kapi.qiaoqiao`）

---

### 步骤 6：配置 iOS Deployment Target

1. 选中 **BillScanWidget** Target
2. **General** → **Deployment Info**
3. 设置 **iOS** 版本为 **16.1** 或更高
   （Live Activity 需要 iOS 16.1+）

---

### 步骤 7：配置 App Groups（重要！）

#### 7.1 主 App 配置
1. 选中 **qiaoqiao** Target
2. **Signing & Capabilities** → **App Groups**
3. 点击 **+** 添加：`group.com.kapi.qiaoqiao.shared`

#### 7.2 Widget Extension 配置
1. 选中 **BillScanWidget** Target
2. **Signing & Capabilities** → 点击 **+ Capability**
3. 添加 **App Groups**
4. 勾选相同的 Group：`group.com.kapi.qiaoqiao.shared`

---

### 步骤 8：配置 Info.plist（Widget Extension）

1. 选中 `BillScanWidget/Info.plist`
2. 确保包含以下内容（我已创建）：

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

---

### 步骤 9：编译测试

1. 选择 **qiaoqiao** Scheme
2. 选择真机或模拟器（iOS 16.1+）
3. 点击 **Run** (Cmd+R)

---

## 🧪 测试步骤

### 方法 1：通过快捷指令 App 测试

1. 打开 **快捷指令** App
2. 点击右上角 **+** 创建新快捷指令
3. 搜索 **"识别账单"**（ScanBillIntent）
4. 添加到快捷指令
5. 运行快捷指令
6. **预期结果**：
   - 灵动岛/锁屏顶部出现卡片
   - 显示 "Hello World!"
   - 5 秒后更新为 "识别完成！测试成功"

### 方法 2：通过 Siri 测试

1. 对 Siri 说："识别账单"
2. 观察 Live Activity 是否出现

### 方法 3：通过代码测试

在主 App 的某个按钮中添加：

```swift
Button("测试 Live Activity") {
    Task {
        let intent = ScanBillIntent()
        _ = try? await intent.perform()
    }
}
```

---

## 🐛 常见问题

### Q1: 找不到 "识别账单" Intent
**解决**：
- 确保 Widget Extension Target 已添加到项目
- Clean Build Folder (Cmd+Shift+K)
- 重新运行主 App

### Q2: Live Activity 没有显示
**检查**：
1. iOS 版本 >= 16.1
2. 设置 → 通知 → Live Activities 已开启
3. 在 Xcode Console 查看日志：`🚀 ScanBillIntent 开始执行`

### Q3: 编译错误 "Cannot find type 'Activity'"
**解决**：
- 确保导入了 `import ActivityKit`
- 确保 Deployment Target >= iOS 16.1

### Q4: Widget Extension 无法找到主 App 的类
**解决**：
- BillScanAttributes.swift 必须同时添加到：
  - ✅ BillScanWidget Target
  - ✅ qiaoqiao Target (主 App)

---

## 📱 下一步

配置完成后，你将看到：

1. **快捷指令 App** 中出现 "识别账单" Intent
2. 执行后，**灵动岛/锁屏** 显示 "Hello World!"
3. 5 秒后自动更新为 "识别完成！测试成功"

成功后，我们可以继续实现：
- ✅ 接收图片参数
- ✅ 调用后端 API
- ✅ 显示真实账单数据
- ✅ 点击跳转到 App

---

## 🎯 关键代码位置

| 功能 | 文件 | 代码位置 |
|-----|------|---------|
| 启动 Live Activity | `ScanBillIntent.swift` | `Activity.request()` |
| 更新 Live Activity | `ScanBillIntent.swift` | `activity.update()` |
| Live Activity UI | `BillScanLiveActivity.swift` | `LockScreenLiveActivityView` |
| 数据结构 | `BillScanAttributes.swift` | `ContentState` |

---

## ✅ 完成检查清单

- [ ] Widget Extension Target 已创建
- [ ] 所有文件已添加到正确的 Target
- [ ] App Groups 已配置（主 App + Widget）
- [ ] Bundle Identifier 正确
- [ ] iOS Deployment Target >= 16.1
- [ ] 项目编译成功
- [ ] 快捷指令 App 中能找到 "识别账单"
- [ ] 运行后 Live Activity 正常显示

---

遇到问题随时问我！🎉
