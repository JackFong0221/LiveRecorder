import SwiftUI
import Combine

@main
struct LiveRecorderApp: App {
    @StateObject private var pythonManager = PythonManager()
    @StateObject private var api = APIClient()

    @State private var selectedTab = 0

    private let tabs: [(title: String, icon: String)] = [
        ("添加", "plus.circle"),
        ("列表", "list.bullet"),
        ("存储", "folder"),
        ("设置", "gearshape"),
    ]

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
            HStack(spacing: 6) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    tabButton(tab.title, icon: tab.icon, index: index)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            // Page content
            pageContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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

    // MARK: - Tab Button

    func tabButton(_ title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        let tabWidth: CGFloat = (360 - 16 - 6 * 3) / 4

        return VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
        }
        .foregroundColor(isSelected ? .accentColor : .secondary)
        .frame(width: tabWidth, height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withTransaction(Transaction(animation: .easeInOut(duration: 0.25))) {
                selectedTab = index
            }
        }
    }

    // MARK: - Pages

    @ViewBuilder
    var pageContent: some View {
        HStack(spacing: 0) {
            AddRecordingView(api: api) { pythonManager.objectWillChange.send() }
                .frame(width: 360)

            RecordingListView(api: api, apiRunning: pythonManager.isRunning)
                .frame(width: 360)

            StorageView(api: api)
                .frame(width: 360)

            SettingsView(api: api)
                .frame(width: 360)
        }
        .frame(width: 360, alignment: .leading)
        .offset(x: -CGFloat(selectedTab) * 360)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .clipped()
    }
}
