import SwiftUI

@main
struct LiveRecorderApp: App {
    @StateObject private var pythonManager = PythonManager()
    @StateObject private var api = APIClient()

    @State private var selectedTab = "add"
    @State private var refreshTrigger = false

    var body: some Scene {
        MenuBarExtra("LiveRecorder", systemImage: "record.circle") {
            mainContent
                .frame(width: 360, height: 480)
        }
        .menuBarExtraStyle(.window)
    }

    var mainContent: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                Circle()
                    .fill(pythonManager.isReady ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(pythonManager.isReady ? "就绪" : "启动中...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("LiveRecorder")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.08))

            // Tab bar
            HStack(spacing: 0) {
                tabButton("添加", icon: "plus.circle", tab: "add")
                tabButton("列表", icon: "list.bullet", tab: "list")
                tabButton("存储", icon: "folder", tab: "storage")
                tabButton("设置", icon: "gearshape", tab: "settings")
            }
            .padding(.top, 6)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case "add":
                    AddRecordingView(api: api) {
                        pythonManager.objectWillChange.send()
                    }
                case "list":
                    RecordingListView(
                        api: api,
                        apiRunning: pythonManager.isRunning
                    )
                case "storage":
                    StorageView(api: api)
                case "settings":
                    SettingsView(api: api)
                default:
                    EmptyView()
                }
            }
            .id(selectedTab)
            .frame(maxHeight: .infinity)

            // Quit button
            HStack {
                Spacer()
                Button("退出 LiveRecorder") {
                    pythonManager.stop()
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
        .onAppear {
            pythonManager.start()
        }
    }

    func tabButton(_ label: String, icon: String, tab: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
            .background(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 2)
    }
}
