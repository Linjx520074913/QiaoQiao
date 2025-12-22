# 网络权限调试步骤

## ✅ 已完成的修改

1. **添加了代理禁用配置** (`BillScanService.swift:118-120`)
   ```swift
   let configuration = URLSessionConfiguration.default
   configuration.connectionProxyDictionary = [:]  // 禁用代理
   let session = URLSession(configuration: configuration)
   ```

2. **添加了 Entitlements**
   - `com.apple.developer.networking.wifi-info`
   - `com.apple.developer.networking.multicast`

3. **添加了 Info.plist 权限**
   - `NSLocalNetworkUsageDescription`
   - `NSBonjourServices`
   - `NSAppTransportSecurity` (允许 HTTP)

---

## 📱 现在测试步骤

### 1. 完全删除并重新安装

**重要**：必须完全删除 App，清除所有权限缓存

在 iPhone 上：
1. 长按 **AppIntent** 图标
2. 选择 **删除 App**
3. 确认**删除 App**（不是移到资源库）

### 2. 重新安装

使用 Xcode 或命令行：
```bash
xcodebuild -project AppIntent.xcodeproj -scheme AppIntent \
  -destination 'name=我的iphone' clean install
```

### 3. 首次打开 App

1. **直接打开 AppIntent App**（不要先运行快捷指令）
2. 如果弹出本地网络权限请求，**点击"好"**
3. 检查 App 界面是否显示"本地网络权限已授予"（绿色✅）

### 4. 验证系统设置

**设置 → 隐私与安全性 → 本地网络 → AppIntent**
- 确认开关是**绿色/开启**状态

### 5. 测试快捷指令

运行你的快捷指令，查看日志输出

---

## 🔍 如果还是失败

### 测试 1：在 App 内部测试网络（绕过 Intent）

修改 `ContentView.swift`，添加测试按钮：

```swift
Button("测试网络") {
    Task {
        do {
            let service = BillScanService.shared
            // 测试一个简单的请求
            let url = URL(string: "http://10.9.190.86:8080/health")!
            let config = URLSessionConfiguration.default
            config.connectionProxyDictionary = [:]
            let session = URLSession(configuration: config)
            let (data, _) = try await session.data(from: url)
            print("✅ 网络测试成功: \(String(data: data, encoding: .utf8) ?? "")")
        } catch {
            print("❌ 网络测试失败: \(error)")
        }
    }
}
```

**如果 App 内部可以访问但 Intent 不行**：
→ 说明是 Intent 的沙盒权限问题

**如果 App 内部也无法访问**：
→ 说明是整体的网络权限配置问题

### 测试 2：使用 Safari 测试

在 iPhone 的 Safari 中访问：
```
http://10.9.190.86:8080/health
```

**如果能访问**：说明网络本身没问题
**如果不能访问**：检查 Mac 和 iPhone 的网络连接

---

## 🎯 可能的原因和解决方案

### 原因 1：开发者账号没有网络权限 Capability

**解决方案**：
1. 打开 Xcode
2. 选择项目 → Target: AppIntent
3. Signing & Capabilities
4. 点击 **+ Capability**
5. 添加 **Access WiFi Information**

### 原因 2：App Group 配置错误

检查 `AppIntent.entitlements` 中的 App Group：
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.dm.AppIntent</string>
</array>
```

确保开发者账号中也创建了这个 App Group。

### 原因 3：URLSession 没有正确配置

已添加禁用代理配置，还可以尝试：
```swift
configuration.timeoutIntervalForRequest = 120
configuration.timeoutIntervalForResource = 120
configuration.waitsForConnectivity = true
```

---

## 📊 日志解读

### 成功的日志：
```
🚀 [Intent] 开始处理...
📸 [Intent] 图片已加载，开始识别...
⏳ [Intent] 正在上传图片并识别...
📸 [BillScan] 开始处理图片...
✅ [BillScan] 图片数据大小: 265960 bytes
🚀 [BillScan] 发送请求...
⏳ [BillScan] 等待响应... (2秒)
⏳ [BillScan] 等待响应... (4秒)
✅ [BillScan] 收到响应（总耗时: 5.3秒）
✅ [Intent] 识别成功: 星巴克 - ¥80.00
```

### 失败的日志（当前问题）：
```
❌ [BillScan] 错误: Error Domain=NSURLErrorDomain Code=-1009
_NSURLErrorNWPathKey=unsatisfied (Local network prohibited)
```

**关键字**：`Local network prohibited` → 本地网络被禁止

---

## 💡 最后的建议

如果以上都不行，可以考虑：

1. **使用 ngrok 或内网穿透**
   ```bash
   ngrok http 8080
   ```
   然后修改 `BillScanService.swift` 中的 `baseURL` 为 ngrok 地址

2. **修改为使用云服务**
   部署后端到云服务器（如 AWS、阿里云等）

3. **联系 Apple 开发者支持**
   如果确认配置都正确但还是不行，可能是系统 bug

---

**下一步**：按照上面的步骤 1-5 重新测试
