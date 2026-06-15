import Foundation

class APIClient: ObservableObject {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: String = "http://127.0.0.1:6006") {
        self.baseURL = baseURL
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
    }

    // MARK: Status

    func checkStatus() async throws -> Bool {
        let data = try await get("/api/status")
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["status"] as? String == "running"
    }

    // MARK: Recordings

    func addRecording(url: String, quality: String = "OD", format: String = "ts") async throws -> Recording {
        let body = ["url": url, "quality": quality, "record_format": format]
        let data = try await post("/api/recordings", body: body)
        let response = try decoder.decode(AddRecordingResponse.self, from: data)
        return response.recording
    }

    func listRecordings() async throws -> [Recording] {
        let data = try await get("/api/recordings")
        return try decoder.decode([Recording].self, from: data)
    }

    func deleteRecording(_ recID: String) async throws {
        _ = try await delete("/api/recordings/\(recID)")
    }

    func startMonitoring(_ recID: String) async throws {
        _ = try await post("/api/recordings/\(recID)/start", body: nil)
    }

    func stopMonitoring(_ recID: String) async throws {
        _ = try await post("/api/recordings/\(recID)/stop", body: nil)
    }

    func stopRecording(_ recID: String) async throws {
        _ = try await post("/api/recordings/\(recID)/stop-recording", body: nil)
    }

    func listRecordingFiles(_ recID: String) async throws -> [RecordingFile] {
        let data = try await get("/api/recordings/\(recID)/files")
        return try decoder.decode([RecordingFile].self, from: data)
    }

    // MARK: Settings

    func getSettings() async throws -> SettingsModel {
        let data = try await get("/api/settings")
        return try decoder.decode(SettingsModel.self, from: data)
    }

    func updateSettings(_ settings: SettingsModel) async throws {
        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(settings)
        let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any] ?? [:]
        _ = try await put("/api/settings", body: json)
    }

    // MARK: Platform Detection

    func detectPlatform(url: String) async throws -> (String?, String?) {
        let body = ["url": url]
        let data = try await post("/api/detect", body: body)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let platform = json?["platform"] as? String
        let key = json?["platform_key"] as? String
        return (platform, key)
    }

    // MARK: HTTP Helpers

    private func get(_ path: String) async throws -> Data {
        let url = URL(string: baseURL + path)!
        let (data, _) = try await session.data(from: url)
        return data
    }

    private func post(_ path: String, body: [String: Any]?) async throws -> Data {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } else {
            request.httpBody = Data()
        }
        let (data, _) = try await session.data(for: request)
        return data
    }

    private func delete(_ path: String) async throws -> Data {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, _) = try await session.data(for: request)
        return data
    }

    private func put(_ path: String, body: [String: Any]) async throws -> Data {
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request)
        return data
    }
}

private struct AddRecordingResponse: Codable {
    let status: String
    let recording: Recording
}
