import SwiftUI

enum FileCategory: String, CaseIterable, Sendable, Codable {
    case documents
    case media
    case code
    case archives
    case apps
    case system
    case other

    var color: Color {
        switch self {
        case .documents: Color(hex: 0x4A90D9)
        case .media:     Color(hex: 0x9B59B6)
        case .code:      Color(hex: 0x2ECC71)
        case .archives:  Color(hex: 0xE67E22)
        case .apps:      Color(hex: 0xE74C3C)
        case .system:    Color(hex: 0x7F8C8D)
        case .other:     Color(hex: 0x5D6D7E)
        }
    }

    var label: String {
        switch self {
        case .documents: "문서"
        case .media:     "미디어"
        case .code:      "코드"
        case .archives:  "압축파일"
        case .apps:      "앱"
        case .system:    "시스템"
        case .other:     "기타"
        }
    }

    var icon: String {
        switch self {
        case .documents: "doc.fill"
        case .media:     "play.rectangle.fill"
        case .code:      "chevron.left.forwardslash.chevron.right"
        case .archives:  "archivebox.fill"
        case .apps:      "app.fill"
        case .system:    "gearshape.fill"
        case .other:     "questionmark.folder.fill"
        }
    }

    static func categorize(extension ext: String) -> FileCategory {
        let lower = ext.lowercased()
        switch lower {
        // Documents
        case "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
             "txt", "rtf", "pages", "numbers", "keynote", "csv":
            return .documents

        // Media
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp", "svg",
             "mp4", "mov", "avi", "mkv", "wmv", "flv", "m4v",
             "mp3", "aac", "flac", "wav", "m4a", "ogg", "wma":
            return .media

        // Code
        case "swift", "py", "js", "ts", "jsx", "tsx", "java", "kt",
             "c", "cpp", "h", "hpp", "m", "mm", "rs", "go",
             "rb", "php", "html", "css", "scss", "json", "xml", "yml", "yaml",
             "sh", "zsh", "bash", "sql", "md", "toml":
            return .code

        // Archives
        case "zip", "tar", "gz", "bz2", "xz", "7z", "rar", "dmg", "iso", "pkg":
            return .archives

        // Apps
        case "app", "ipa", "framework", "dylib", "so":
            return .apps

        // System
        case "plist", "kext", "log", "crash":
            return .system

        default:
            return .other
        }
    }
}
