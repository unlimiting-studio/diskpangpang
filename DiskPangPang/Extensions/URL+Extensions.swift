import Foundation

extension URL {
    var isSystemProtected: Bool {
        let protectedPaths = [
            "/System", "/usr", "/bin", "/sbin",
            "/Library/Apple", "/private/var/db",
            "/cores", "/dev"
        ]
        let p = self.path
        return protectedPaths.contains { p == $0 || p.hasPrefix($0 + "/") }
    }

    var volumeName: String {
        let components = pathComponents
        if components.count >= 3 && components[1] == "Volumes" {
            return components[2]
        }
        return "Macintosh HD"
    }
}

extension UInt64 {
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter.string(fromByteCount: Int64(self))
    }
}
