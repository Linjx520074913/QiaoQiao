# 性能优化说明

## 当前性能

根据日志显示，识别过程可能需要较长时间（取决于图片大小和服务器性能）。

## 处理流程

1. **图片上传** (~1秒)
   - 图片大小：~260KB
   - 网络传输时间

2. **OCR 识别** (1-3秒)
   - RapidOCR 提取文字
   - 取决于图片复杂度

3. **LLM 解析** (2-5秒)
   - Qwen 模型解析
   - 使用 `qwen2.5:1.5b` 小模型（/scan/fast）

**总耗时：约 3-8 秒**

## 优化建议

### 1. 后端优化

#### a) 使用更小的模型
```python
# 已经在使用最快的配置
FAST_MODEL = "qwen2.5:1.5b"  # 最小模型
skip_items = True             # 跳过商品明细
clean_text = True             # 清理文本
```

#### b) 优化图片压缩
在 `BillScanService.swift` 中调整压缩率：
```swift
// 当前：0.8（高质量）
image.jpegData(compressionQuality: 0.8)

// 可以降低到 0.5-0.6（更快但可能影响识别）
image.jpegData(compressionQuality: 0.6)
```

#### c) 后端缓存
如果同一张图片多次识别，可以添加缓存

### 2. 网络优化

#### a) 确保良好的 WiFi 信号
- Mac 和 iPhone 在同一个路由器附近
- 避免墙壁遮挡

#### b) 检查后端性能
```bash
# 查看后端资源占用
top -pid $(lsof -ti :8080)

# 检查 Ollama 是否使用 GPU
ollama ps
```

### 3. 用户体验优化

#### a) 添加进度提示（已实现）
- 每 2 秒打印等待时间
- 显示总耗时

#### b) 超时时间
- 当前：120 秒
- 如果经常超时，可以增加到 180 秒

## 查看详细日志

在 Xcode Console 中查看：
```
⏳ [BillScan] 等待响应... (2秒)
⏳ [BillScan] 等待响应... (4秒)
⏳ [BillScan] 等待响应... (6秒)
✅ [BillScan] 收到响应（总耗时: 7.3秒）
```

## 快速模式 vs 标准模式

### /scan/fast（当前使用）
- 模型：qwen2.5:1.5b
- 跳过商品明细
- 速度：2-5 秒
- 准确度：中等

### /scan（标准模式）
- 模型：qwen2.5:3b
- 包含商品明细
- 速度：5-10 秒
- 准确度：高

## 如果需要更快的速度

可以修改 `BillScanService.swift`：
```swift
// 降低图片质量（更快但可能降低识别率）
guard let imageData = image.jpegData(compressionQuality: 0.5) else {
    ...
}

// 或者调整图片尺寸
let maxSize: CGFloat = 1024
if image.size.width > maxSize || image.size.height > maxSize {
    let resized = image.resize(to: maxSize)
    imageData = resized.jpegData(compressionQuality: 0.7)
}
```

## 预期性能

在良好网络条件下：
- **最快**：2-3 秒（简单账单）
- **平均**：4-6 秒（普通账单）
- **较慢**：7-10 秒（复杂账单）

如果超过 10 秒，建议检查：
1. Mac 的 CPU/内存占用
2. WiFi 信号强度
3. Ollama 模型是否正常运行
