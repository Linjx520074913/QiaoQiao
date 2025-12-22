//
//  ContentView.swift
//  qiaoqiao
//
//  主页面 - 图片选择和扫描
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var isScanning = false
    @State private var scanResult: ScanResult?
    @State private var showResult = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var serverStatus: String = "检查中..."
    @State private var skipItems = false
    @State private var useFastMode = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showDebugCard = true // 调试模式：直接显示卡片

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // 测试按钮组
                        VStack(spacing: 12) {
                            // 测试1：创建待确认账单
                            Button(action: {
                                AppStateManager.shared.createMockPendingBill()
                            }) {
                                Label("测试：App内账单卡片", systemImage: "bell.badge")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .cornerRadius(12)
                            }

                            // 测试2：启动 Live Activity
                            Button(action: {
                                testLiveActivity()
                            }) {
                                Label("测试：桌面Live Activity", systemImage: "rectangle.stack.badge.play")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // 服务器状态
                        Text(serverStatus)
                            .font(.caption)
                            .foregroundColor(serverStatus.contains("✓") ? .green : .red)
                            .padding(.top)

                    // 图片预览
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .padding()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 300)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("未选择图片")
                                        .foregroundColor(.secondary)
                                }
                            )
                            .padding()
                    }

                    // 选项开关
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("快速模式", isOn: $useFastMode)
                        Toggle("跳过商品明细", isOn: $skipItems)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // 按钮组
                    HStack(spacing: 12) {
                        // 选择图片
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("选择图片", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        // 拍照
                        Button {
                            showCamera = true
                        } label: {
                            Label("拍照", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    // 开始识别按钮
                    Button {
                        Task {
                            await scanImage()
                        }
                    } label: {
                        if isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.6))
                                .cornerRadius(10)
                        } else {
                            Text("开始识别")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedImage == nil ? Color.gray : Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(selectedImage == nil || isScanning)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }

            // 调试卡片 - 直接在主页面显示
            if showDebugCard {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDebugCard = false
                    }

                BillCardView(
                    record: createDebugRecord(),
                    backgroundColor: Color(.systemGroupedBackground)
                ) {
                    print("调试：点击记账按钮")
                    showDebugCard = false
                }
                .padding(20)
                .transition(.scale.combined(with: .opacity))
            }
        }
            .navigationTitle("KAPI - 智能账单识别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: BillListView()) {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let result = scanResult, let image = selectedImage {
                    ResultView(scanResult: result, image: image)
                        .presentationBackground(.clear)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "未知错误")
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .task {
                await checkHealth()
            }
        }
    }

    // MARK: - 健康检查
    private func checkHealth() async {
        do {
            _ = try await apiService.healthCheck()
            serverStatus = "✓ 服务器连接成功"
        } catch {
            serverStatus = "✗ 服务器连接失败"
        }
    }

    // MARK: - 扫描图片
    private func scanImage() async {
        guard let image = selectedImage else { return }

        isScanning = true
        defer { isScanning = false }

        do {
            let result = try await apiService.scanBill(
                image: image,
                skipItems: skipItems,
                useFastMode: useFastMode
            )

            if result.success {
                scanResult = result
                showResult = true
            } else {
                errorMessage = result.error ?? "识别失败"
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - 测试 Live Activity
    private func testLiveActivity() {
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

        // 保存到持久化存储（用于深度链接）
        if let data = try? JSONEncoder().encode(mockBill) {
            UserDefaults.standard.set(data, forKey: "pendingBill_\(mockBill.id)")
        }

        // 启动 Live Activity
        if #available(iOS 16.2, *) {
            LiveActivityManager.shared.startActivity(from: mockBill, items: mockItems)
            print("✅ 已启动 Live Activity，请查看桌面/锁屏")
        } else {
            print("❌ Live Activity 需要 iOS 16.2+")
        }
    }

    // MARK: - 创建调试数据（星巴克简化版 - 卡片3）
    private func createDebugRecord() -> BillRecord {
        let invoice = Invoice(
            invoiceType: "咖啡店",
            invoiceNumber: "1234567890",
            invoiceDate: "2025-12-17 09:45:00",
            sellerName: "星巴克咖啡",
            buyerName: nil,
            buyerPhone: nil,
            totalAmount: 45.00,
            items: nil,  // 无商品明细
            remarks: nil
        )

        return BillRecord(
            invoice: invoice,
            image: nil,
            scanPerformance: ["total": 2.5, "ocr": 0.8, "parse": 1.7]
        )
    }
}

// MARK: - 相机选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
}
