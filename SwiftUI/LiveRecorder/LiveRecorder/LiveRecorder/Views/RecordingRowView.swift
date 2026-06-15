import SwiftUI

struct RecordingRowView: View {
    let recording: Recording
    let onStop: () -> Void
    let onStart: () -> Void
    let onDelete: () -> Void
    let onOpenFolder: () -> Void
    let apiRunning: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                // Status indicator
                Circle()
                    .fill(colorForState(recording.state))
                    .frame(width: 8, height: 8)

                // Name + platform
                VStack(alignment: .leading, spacing: 2) {
                    Text(recording.streamerName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text(recording.platform)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                Text(recording.statusText)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorForState(recording.state).opacity(0.15))
                    .cornerRadius(4)
            }

            // Recording info row
            if recording.isRecording {
                HStack(spacing: 16) {
                    // Duration
                    if !recording.duration.isEmpty {
                        Label(recording.duration, systemImage: "clock")
                            .font(.caption2)
                    }
                    // Speed
                    if recording.speed != "X KB/s" {
                        Label(recording.speed, systemImage: "speedometer")
                            .font(.caption2)
                    }
                    Spacer()
                }
                .foregroundColor(.secondary)
            }

            // Action buttons
            HStack(spacing: 8) {
                Spacer()

                // Record / Stop button
                if recording.isRecording {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("停止录制")
                } else if recording.monitorStatus {
                    Button(action: onStart) {
                        Image(systemName: "play.circle")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .help("开始录制")
                }

                // Start / Stop monitoring
                if recording.monitorStatus {
                    Button(action: onStop) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("停止监控")
                } else {
                    Button(action: onStart) {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("开始监控")
                }

                // Open folder
                Button(action: onOpenFolder) {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("打开文件夹")

                // Delete
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("删除")
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }

    func colorForState(_ state: String) -> Color {
        switch state {
        case "recording": return .green
        case "live", "live_broadcasting": return .blue
        case "checking", "status_checking", "preparing_recording": return .purple
        case "error", "recording_error", "live_status_check_error": return .red
        case "offline": return .orange
        default: return .gray
        }
    }
}
