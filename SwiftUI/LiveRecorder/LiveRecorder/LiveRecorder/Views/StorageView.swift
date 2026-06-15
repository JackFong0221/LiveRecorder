import SwiftUI

struct StorageView: View {
    @ObservedObject var api: APIClient

    @State private var recordings: [Recording] = []
    @State private var selectedRecording: Recording?
    @State private var files: [RecordingFile] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            Text("存储管理")
                .font(.headline)

            // Recording selector
            if recordings.isEmpty {
                Spacer()
                Text("暂无录制").foregroundColor(.secondary)
                Spacer()
            } else {
                Picker("选择录制", selection: $selectedRecording) {
                    Text("选择直播间...").tag(nil as Recording?)
                    ForEach(recordings) { rec in
                        Text("\(rec.streamerName) (\(rec.platform))")
                            .tag(rec as Recording?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedRecording) { loadFiles() }

                // File list
                if isLoading {
                    ProgressView()
                } else if files.isEmpty {
                    if selectedRecording != nil {
                        Text("暂无录制文件")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(files) { file in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Text(formatSize(file.size))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
                                    }) {
                                        Image(systemName: "play.circle")
                                    }
                                    .buttonStyle(.plain)
                                    Button(action: {
                                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.path)])
                                    }) {
                                        Image(systemName: "folder")
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(6)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear { loadRecordings() }
    }

    private func loadRecordings() {
        Task {
            do {
                let recs = try await api.listRecordings()
                await MainActor.run { recordings = recs }
            } catch {}
        }
    }

    private func loadFiles() {
        guard let rec = selectedRecording else { return }
        isLoading = true
        Task {
            do {
                let f = try await api.listRecordingFiles(rec.recID)
                await MainActor.run {
                    files = f.sorted { $0.modified > $1.modified }
                    isLoading = false
                }
            } catch {
                await MainActor.run { isLoading = false }
            }
        }
    }

    private func formatSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
