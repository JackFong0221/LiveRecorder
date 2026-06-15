import SwiftUI

struct AddRecordingView: View {
    @ObservedObject var api: APIClient
    var onRecordingAdded: () -> Void

    @State private var url = ""
    @State private var quality = "OD"
    @State private var format = "ts"
    @State private var detectedPlatform = ""
    @State private var detectedKey = ""
    @State private var isAdding = false
    @State private var isDetecting = false
    @State private var errorMessage: String?

    private let qualities = ["OD", "UHD", "HD", "SD", "LD"]
    private let formats = ["ts", "mp4", "flv", "mkv", "mov"]

    var body: some View {
        VStack(spacing: 16) {
            Text("添加直播间")
                .font(.headline)

            // URL input
            VStack(alignment: .leading, spacing: 4) {
                Text("直播间链接")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("粘贴直播间链接...", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: url) { detectPlatform() }
            }

            // Auto-detected platform
            if !detectedPlatform.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("检测到: \(detectedPlatform)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Quality & Format
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("画质")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $quality) {
                        ForEach(qualities, id: \.self) { q in
                            Text(q).tag(q)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("格式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $format) {
                        ForEach(formats, id: \.self) { f in
                            Text(f.uppercased()).tag(f)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                }
            }

            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Add button
            Button(action: addRecording) {
                if isAdding {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("添加")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(url.isEmpty || isAdding)
        }
        .padding()
    }

    private func detectPlatform() {
        guard !url.isEmpty else {
            detectedPlatform = ""
            detectedKey = ""
            return
        }
        isDetecting = true
        Task {
            do {
                let (plat, key) = try await api.detectPlatform(url: url)
                await MainActor.run {
                    detectedPlatform = plat ?? ""
                    detectedKey = key ?? ""
                    isDetecting = false
                }
            } catch {
                await MainActor.run {
                    isDetecting = false
                }
            }
        }
    }

    private func addRecording() {
        isAdding = true
        errorMessage = nil
        Task {
            do {
                _ = try await api.addRecording(url: url, quality: quality, format: format)
                await MainActor.run {
                    url = ""
                    isAdding = false
                    detectedPlatform = ""
                    onRecordingAdded()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "添加失败: \(error.localizedDescription)"
                    isAdding = false
                }
            }
        }
    }
}
