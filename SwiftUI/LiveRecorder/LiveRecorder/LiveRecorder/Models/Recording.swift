import Foundation

struct Recording: Identifiable, Codable, Hashable {
    var id: String { recID }
    let recID: String
    var url: String
    var streamerName: String
    var title: String
    var platform: String
    var platformKey: String
    var quality: String
    var recordFormat: String
    var segmentRecord: Bool
    var segmentTime: String
    var monitorStatus: Bool
    var outputDir: String
    var recordingDir: String
    var isLive: Bool
    var isRecording: Bool
    var state: String
    var speed: String
    var duration: String
    var startTime: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case recID = "rec_id"
        case url
        case streamerName = "streamer_name"
        case title
        case platform
        case platformKey = "platform_key"
        case quality
        case recordFormat = "record_format"
        case segmentRecord = "segment_record"
        case segmentTime = "segment_time"
        case monitorStatus = "monitor_status"
        case outputDir = "output_dir"
        case recordingDir = "recording_dir"
        case isLive = "is_live"
        case isRecording = "is_recording"
        case state, speed, duration
        case startTime = "start_time"
        case createdAt = "created_at"
    }

    var stateColor: String {
        switch state {
        case "recording": return "green"
        case "live": return "blue"
        case "checking": return "purple"
        case "error": return "red"
        case "offline": return "orange"
        default: return "gray"
        }
    }

    var statusText: String {
        switch state {
        case "recording": return "录制中"
        case "monitoring": return "监控中"
        case "checking": return "检测中"
        case "live": return "直播中"
        case "error": return "错误"
        case "offline": return "未开播"
        case "stopped": return "已停止"
        default: return state
        }
    }
}

struct RecordingFile: Codable, Identifiable {
    var id: String { path }
    let name: String
    let path: String
    let size: Int
    let modified: String
}

struct SettingsModel: Codable {
    var videoSavePath: String
    var videoFormat: String
    var recordQuality: String
    var loopTimeSeconds: Int
    var segmentTime: String
    var enableProxy: Bool
    var proxyAddress: String
    var convertToMp4: Bool
    var deleteOriginal: Bool
    var defaultLiveSource: String
    var forceHttps: Bool
    var folderByPlatform: Bool
    var folderByAuthor: Bool

    enum CodingKeys: String, CodingKey {
        case videoSavePath = "video_save_path"
        case videoFormat = "video_format"
        case recordQuality = "record_quality"
        case loopTimeSeconds = "loop_time_seconds"
        case segmentTime = "segment_time"
        case enableProxy = "enable_proxy"
        case proxyAddress = "proxy_address"
        case convertToMp4 = "convert_to_mp4"
        case deleteOriginal = "delete_original"
        case defaultLiveSource = "default_live_source"
        case forceHttps = "force_https"
        case folderByPlatform = "folder_by_platform"
        case folderByAuthor = "folder_by_author"
    }
}
