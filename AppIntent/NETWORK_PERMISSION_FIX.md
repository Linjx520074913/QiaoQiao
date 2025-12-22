# 本地网络权限问题解决方案

## 问题原因

iOS 的安全限制：**App Intent 通过快捷指令后台运行时，无法访问本地网络**，即使 App 本身已授予权限。

错误信息：`Local network prohibited`

---

## ❌ 已尝试但无效的方案

1. ✗ Info.plist 中的 `NSLocalNetworkUsageDescription`
2. ✗ Info.plist 中的 `NSBonjourServices`
3. ✗ Entitlements 中的 `wifi-info` 和 `multicast`
4. ✗ 系统设置中手动授予本地网络权限

**原因**：快捷指令的后台运行器（BackgroundShortcutRunner）是独立的进程，不继承 App 权限。

---

## ✅ 可行的解决方案

### 方案 1：使用公网 IP（临时方案）

如果你的 Mac 有公网 IP 或者使用了内网穿透（ngrok、frp 等），可以直接使用公网地址。

#### 步骤：

1. **获取公网 IP**（或使用内网穿透）
   ```bash
   # 使用 ngrok
   ngrok http 8080
   ```

2. **修改 `BillScanService.swift`**
   ```swift
   // 替换这一行：
   private let baseURL = "http://10.9.190.86:8080"

   // 改为公网地址：
   private let baseURL = "https://your-ngrok-id.ngrok.io"
   ```

**优点**：最简单，立即可用
**缺点**：需要公网或内网穿透，可能有安全风险

---

### 方案 2：在 Mac 上开启远程访问（推荐）

通过 Mac 的共享功能，让后端服务监听在所有网络接口上。

#### 步骤：

1. **修改后端服务**（`backend/server.py`）
   ```python
   # 找到这一行：
   uvicorn.run(app, host="127.0.0.1", port=8080)

   # 改为监听所有接口：
   uvicorn.run(app, host="0.0.0.0", port=8080)
   ```

2. **在 Mac 上允许防火墙规则**
   ```bash
   # 检查防火墙状态
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

   # 如果启用了，添加 Python 到允许列表
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/python3
   ```

3. **确认 iPhone 可以访问**
   - 在 Safari 中打开：`http://10.9.190.86:8080/health`
   - 应该返回：`{"status": "ok"}`

**优点**：无需外网，安全
**缺点**：需要修改后端配置

---

### 方案 3：完全重写为独立 App（最佳长期方案）

不使用 App Intent，而是创建一个独立的 App，通过 URL Scheme 或 Share Extension 启动。

#### 架构：
```
快捷指令
  ↓
1. 截屏
2. 通过 URL Scheme 打开 App（传递图片）
3. App 显示加载界面
4. App 识别账单
5. App 显示结果
```

#### 优点：
- ✅ 完全控制 UI/UX
- ✅ 可以显示实时进度
- ✅ 本地网络权限正常工作
- ✅ 可以使用 Live Activity

#### 缺点：
- ⚠️ 需要重写代码
- ⚠️ 会打开 App（无法完全后台运行）

---

## 🔍 调试：检查权限状态

### 检查 App 的本地网络权限

在 iPhone 上：
1. **设置 → 隐私与安全性 → 本地网络**
2. 找到 **AppIntent**，确认是**绿色/开启**

### 检查后端服务是否可访问

在 iPhone 的 Safari 中访问：
```
http://10.9.190.86:8080/health
```

**预期结果**：
```json
{"status": "ok"}
```

**如果无法访问**：
- 检查 Mac 和 iPhone 是否在同一 WiFi
- 检查 Mac 的防火墙设置
- 检查后端服务是否在运行：`lsof -ti :8080`

### 检查快捷指令的网络权限

在快捷指令中添加测试步骤：
```
1. 获取 URL 内容
   URL: http://10.9.190.86:8080/health

2. 显示通知
   标题: [URL 内容]
```

**如果成功**：说明快捷指令有网络权限，问题可能在别处
**如果失败**：确认是快捷指令的网络限制问题

---

## 💡 推荐的临时解决方案

**最快的解决方法**：使用方案 2（修改后端监听地址）

1. 编辑 `backend/server.py`，将 `host="127.0.0.1"` 改为 `host="0.0.0.0"`
2. 重启后端服务
3. 在 iPhone 的 Safari 中测试 `http://10.9.190.86:8080/health`
4. 确认可访问后，重新运行快捷指令

如果还是不行，可能需要在 Xcode 中手动配置 Capabilities：
1. 打开 `AppIntent.xcodeproj`
2. 选择 Target: **AppIntent**
3. 切换到 **Signing & Capabilities** 标签
4. 点击 **+ Capability**
5. 添加 **Access WiFi Information**
6. 重新构建并安装

---

## 📞 需要帮助？

如果以上方案都不行，请提供：
1. `lsof -ti :8080` 的输出（检查后端是否运行）
2. iPhone Safari 访问 `http://10.9.190.86:8080/health` 的结果
3. **设置 → 隐私与安全性 → 本地网络** 中 AppIntent 的开关状态截图
