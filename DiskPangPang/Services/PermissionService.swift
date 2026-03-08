import AppKit

enum PermissionService {
    static var hasFullDiskAccess: Bool {
        let testPaths = [
            NSHomeDirectory() + "/Library/Mail",
            NSHomeDirectory() + "/Library/Safari"
        ]

        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return true
            }
        }
        return false
    }

    static func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}
