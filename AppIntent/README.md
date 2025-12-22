# 消费提醒 App Intent

这个项目实现了一个 iOS App Intent，可以通过快捷指令在主屏幕顶部显示消费提醒卡片。

## 功能特点

- 支持通过快捷指令触发
- 在主屏幕顶部显示 Live Activity 卡片
- 支持灵动岛（Dynamic Island）显示
- 自动生成简洁友好的消费提醒文本

## 文件结构

```
AppIntent/
├── ShowExpenseIntent.swift           # App Intent 定义
├── ExpenseActivityAttributes.swift   # Live Activity 数据模型
├── ExpenseMessageGenerator.swift     # 文本生成工具类
├── ExpenseActivityManager.swift      # Live Activity 管理器
├── ExpenseActivityView.swift         # Live Activity 视图
└── Info.plist                        # 配置文件
```

## 使用方法

### 1. Xcode 配置

1. 打开 `AppIntent.xcodeproj`
2. 将所有新创建的 `.swift` 文件添加到项目中
3. 确保 Info.plist 已正确配置
4. 编译并运行到真机（Live Activity 不支持模拟器）

### 2. 创建快捷指令

1. 打开"快捷指令" App
2. 创建新快捷指令
3. 添加"运行 App Intent"操作
4. 选择"显示消费卡片"
5. 设置参数：
   - 商家：例如"星巴克"
   - 金额：例如 45.00
   - 时间：例如"12:30"（可选）

### 3. 触发快捷指令

- 手动运行快捷指令
- 通过 Siri 语音触发
- 通过自动化规则触发

## 文本生成逻辑

`ExpenseMessageGenerator` 会根据商家名称长度自动选择最合适的显示格式：

- 商家名 ≤ 4 字：`在XX消费¥45.00`
- 商家名 ≤ 6 字：`XXXX ¥45.00`
- 商家名 > 6 字：`XXXX ¥45.00`

示例：
- `在星巴克消费¥45.00`
- `肯德基 ¥28.50`
- `麦当劳 ¥32.00`

## 技术要点

- **最低系统要求**：iOS 16.1+（Live Activity 支持）
- **真机调试**：Live Activity 必须在真机上测试
- **权限配置**：需要在 Info.plist 中启用 Live Activity 支持
- **App Intent**：支持快捷指令集成

## 开发注意事项

1. Live Activity 不支持模拟器，必须使用真机测试
2. 需要在 Xcode 中正确配置 Signing & Capabilities
3. 建议在真实场景下测试文本显示效果
4. Dynamic Island 功能需要 iPhone 14 Pro 及以上机型

## 自定义

如需自定义文本格式，可修改 `ExpenseMessageGenerator.swift` 中的 `generate` 方法。

如需调整 UI 样式，可修改 `ExpenseActivityView.swift` 中的视图代码。
