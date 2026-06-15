import SwiftUI

struct RecordingListView: View {
    @ObservedObject var api: APIClient
    let apiRunning: Bool

    @State private var recordings: [Recording] = []
    @State private var isLoading = false
    @State private var filter: String = "all"
    @State private var errorMessage: String?

    private let filters = [
        ("all", "全部"),
        ("recording", "录制中"),
        ("monitoring", "监控中"),
        ("stopped", "已停止"),
    ]

    var body: some View {
        VStack(spacing: 8) {
            Text("录制列表")
                .font(.headline)

            // Filter tabs
            Picker("筛选", selection: $filter) {
                ForEach(filters, id: \.0) { (key, label) in
                    Text(label).tag(key)
                }
            }
            .pickerStyle(.segmented)
            .font(.caption)

            // List
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredRecordings.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "video.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无录制")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredRecordings) { rec in
                            RecordingRowView(
                                recording: rec,
                                onStop: { handleStop(rec) },
                                onStart: { handleStart(rec) },
                                onDelete: { handleDelete(rec) },
                                onOpenFolder: { openFolder(rec) },
                                apiRunning: apiRunning
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            // Refresh button
            HStack {
                Spacer()
                Button("刷新") {
                    loadRecordings()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
        .padding()
        .onAppear { loadRecordings() }
    }

    private var filteredRecordings: [Recording] {
        switch filter {
        case "recording":
            return recordings.filter { $0.isRecording }
        case "monitoring":
            return recordings.filter { $0.monitorStatus && !$0.isRecording }
        case "stopped":
            return recordings.filter { !$0.monitorStatus }
        default:
            return recordings
        }
    }

    func loadRecordings() {
        isLoading = true
        Task {
            do {
                let recs = try await api.listRecordings()
                await MainActor.run {
                    recordings = recs.reversed()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func handleStop(_ rec: Recording) {
        Task {
            if rec.isRecording {
                try? await api.stopRecording(rec.recID)
            }
            try? await api.stopMonitoring(rec.recID)
            await MainActor.run { loadRecordings() }
        }
    }

    private func handleStart(_ rec: Recording) {
        Task {
            try? await api.startMonitoring(rec.recID)
            await MainActor.run { loadRecordings() }
        }
    }

    private func handleDelete(_ rec: Recording) {
        Task {
            try? await api.stopMonitoring(rec.recID)
            try? await api.deleteRecording(rec.recID)
            await MainActor.run { loadRecordings() }
        }
    }

    private func openFolder(_ rec: Recording) {
        guard !rec.recordingDir.isEmpty else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: rec.recordingDir))
    }
}
