import Combine
import Foundation
import AppKit

class PythonManager: ObservableObject {
    @Published var isRunning = false
    @Published var isReady = false

    private var process: Process?
    private let api = APIClient()
    private let pythonPath: String
    private let serverModule: String

    init(
        pythonPath: String = "/usr/local/bin/python3.12",
        serverModule: String = "python_backend.server"
    ) {
        self.pythonPath = pythonPath
        self.serverModule = serverModule
    }

    func start() {
        guard !isRunning else { return }

        let bundleDir = Bundle.main.resourcePath ?? ""
        let projectDir: String
        if bundleDir.contains(".app") {
            // Running from .app bundle — python_backend is bundled inside Resources/
            projectDir = bundleDir
        } else {
            // Dev mode — find the project root
            projectDir = findProjectRoot() ?? bundleDir
        }

        let env = [
            "LIVERECORDER_CONFIG_DIR": projectDir + "/python_backend/config"
        ]

        let process = Process()
        process.executableURL = URL(fileURLWithPath: pythonPath)
        process.arguments = ["-m", serverModule]
        process.currentDirectoryURL = URL(fileURLWithPath: projectDir)

        var environment = ProcessInfo.processInfo.environment
        for (key, value) in env {
            environment[key] = value
        }
        process.environment = environment

        process.standardOutput = Pipe()
        process.standardError = Pipe()

        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.isReady = false
            }
        }

        do {
            try process.run()
            self.process = process
            isRunning = true
            waitForReady()
        } catch {
            print("Failed to start Python daemon: \(error)")
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
        isReady = false
    }

    private func waitForReady(retries: Int = 30) {
        Task {
            for _ in 0..<retries {
                do {
                    if try await api.checkStatus() {
                        DispatchQueue.main.async {
                            self.isReady = true
                        }
                        return
                    }
                } catch {
                    // not ready yet
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func findProjectRoot() -> String? {
        let fm = FileManager.default
        var url = URL(fileURLWithPath: #file)
        for _ in 1...10 {
            url = url.deletingLastPathComponent()
            let candidate = url.appendingPathComponent("python_backend").appendingPathComponent("server.py")
            if fm.fileExists(atPath: candidate.path) {
                return url.path
            }
        }
        return nil
    }
}
