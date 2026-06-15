import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var api: APIClient

    @State private var videoSavePath: String = ""
    @State private var recordQuality: String = "OD"
    @State private var videoFormat: String = "ts"
    @State private var defaultLiveSource: String = "FLV"
    @State private var loopTimeSeconds: Double = 180
    @State private var segmentTime: Double = 1800
    @State private var convertToMp4: Bool = true
    @State private var deleteOriginal: Bool = false
    @State private var folderByPlatform: Bool = true
    @State private var folderByAuthor: Bool = true
    @State private var enableProxy: Bool = false
    @State private var proxyAddress: String = ""

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saveMessage: String?

    private let qualities = ["OD", "UHD", "HD", "SD", "LD"]
    private let formats = ["ts", "mp4", "flv", "mkv", "mov"]
    private let sources = ["FLV", "HLS"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    // Save path
                    Group {
                        Text("保存路径").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        HStack {
                            TextField(videoSavePath.isEmpty ? "默认: downloads/" : videoSavePath, text: $videoSavePath)
                                .textFieldStyle(.roundedBorder).font(.caption)
                            Button("浏览...") {
                                selectFolder()
                            }
                            .buttonStyle(.borderless).font(.caption)
                        }
                    }

                    // Recording
                    Group {
                        Text("录制设置").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        labeledPicker("画质", selection: $recordQuality, options: qualities)
                        labeledPicker("格式", selection: $videoFormat, options: formats)
                        labeledPicker("流源", selection: $defaultLiveSource, options: sources)

                        HStack {
                            Text("检测间隔").font(.caption)
                            Spacer()
                            Slider(value: $loopTimeSeconds, in: 30...600, step: 30)
                            Text("\(Int(loopTimeSeconds))s").font(.caption).frame(width: 40)
                        }

                        HStack {
                            Text("分段时长").font(.caption)
                            Spacer()
                            Slider(value: $segmentTime, in: 600...7200, step: 300)
                            Text("\(Int(segmentTime))s").font(.caption).frame(width: 40)
                        }

                        Toggle("自动转码 MP4", isOn: $convertToMp4).font(.caption)
                    }

                    // Folders
                    Group {
                        Text("文件夹").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        Toggle("按平台分文件夹", isOn: $folderByPlatform).font(.caption)
                        Toggle("按主播分文件夹", isOn: $folderByAuthor).font(.caption)
                    }

                    // Proxy
                    Group {
                        Text("代理").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                        Toggle("启用代理", isOn: $enableProxy).font(.caption)
                        if enableProxy {
                            TextField("http://127.0.0.1:7890", text: $proxyAddress)
                                .textFieldStyle(.roundedBorder).font(.caption)
                        }
                    }

                    if let msg = saveMessage {
                        Text(msg).font(.caption).foregroundColor(.green)
                    }

                    Button(action: saveSettings) {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("保存设置").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .onAppear { loadSettings() }
    }

    private func labeledPicker(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in Text(opt).tag(opt) }
            }
            .pickerStyle(.menu).frame(width: 100)
        }
    }

    private func loadSettings() {
        Task {
            do {
                let s = try await api.getSettings()
                await MainActor.run {
                    videoSavePath = s.videoSavePath
                    recordQuality = s.recordQuality
                    videoFormat = s.videoFormat
                    defaultLiveSource = s.defaultLiveSource
                    loopTimeSeconds = Double(s.loopTimeSeconds)
                    segmentTime = Double(s.segmentTime) ?? 1800
                    convertToMp4 = s.convertToMp4
                    deleteOriginal = s.deleteOriginal
                    folderByPlatform = s.folderByPlatform
                    folderByAuthor = s.folderByAuthor
                    enableProxy = s.enableProxy
                    proxyAddress = s.proxyAddress
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }

    private func saveSettings() {
        isSaving = true
        let model = SettingsModel(
            videoSavePath: videoSavePath,
            videoFormat: videoFormat,
            recordQuality: recordQuality,
            loopTimeSeconds: Int(loopTimeSeconds),
            segmentTime: String(Int(segmentTime)),
            enableProxy: enableProxy,
            proxyAddress: proxyAddress,
            convertToMp4: convertToMp4,
            deleteOriginal: deleteOriginal,
            defaultLiveSource: defaultLiveSource,
            forceHttps: true,
            folderByPlatform: folderByPlatform,
            folderByAuthor: folderByAuthor
        )
        Task {
            do {
                try await api.updateSettings(model)
                await MainActor.run {
                    saveMessage = "已保存"
                    isSaving = false
                }
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run { saveMessage = nil }
            } catch {
                await MainActor.run {
                    saveMessage = "保存失败"
                    isSaving = false
                }
            }
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK {
            videoSavePath = panel.url?.path ?? ""
        }
    }
}
