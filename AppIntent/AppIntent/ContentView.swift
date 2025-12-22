//
//  ContentView.swift
//  AppIntent
//
//  Created by linjx on 2025/12/22.
//

import SwiftUI

struct ContentView: View {
    @State private var permissionGranted = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("消费提醒")
                .font(.title)
                .fontWeight(.bold)

            Text("通过快捷指令扫描账单")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 12) {
                Label("使用步骤", systemImage: "list.number")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text("1.")
                            .fontWeight(.medium)
                        Text("打开\"快捷指令\"App")
                    }

                    HStack(alignment: .top) {
                        Text("2.")
                            .fontWeight(.medium)
                        Text("创建快捷指令：截屏 → 显示消费卡片")
                    }

                    HStack(alignment: .top) {
                        Text("3.")
                            .fontWeight(.medium)
                        Text("运行快捷指令即可识别账单")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Spacer()

            if permissionGranted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("本地网络权限已授予")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "wifi.exclamationmark")
                            .foregroundColor(.orange)
                        Text("等待本地网络权限...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Text("如果弹出权限请求，请选择\"好\"")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .task {
            // 检测权限
            await checkPermission()
        }
    }

    private func checkPermission() async {
        let url = URL(string: "http://10.9.190.86:8080/health")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        do {
            let _ = try await URLSession.shared.data(for: request)
            permissionGranted = true
        } catch {
            permissionGranted = false
        }
    }
}

#Preview {
    ContentView()
}
