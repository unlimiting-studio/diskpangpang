import Foundation

struct DeletionResult: Sendable {
    let deletedCount: Int
    let freedSize: UInt64
    let errors: [DeletionError]
}

struct DeletionError: Identifiable, Sendable {
    let id = UUID()
    let url: URL
    let message: String
}

actor DeletionService {
    private let protectedPrefixes = [
        "/System", "/usr", "/bin", "/sbin",
        "/Library/Apple", "/private/var/db",
        "/cores", "/dev", "/etc", "/tmp", "/var"
    ]

    func delete(items: [CollectorItem]) -> DeletionResult {
        // Sort by path depth descending (delete deepest first)
        let sorted = items.sorted { $0.url.pathComponents.count > $1.url.pathComponents.count }

        var deletedCount = 0
        var freedSize: UInt64 = 0
        var errors: [DeletionError] = []

        for item in sorted {
            let path = item.url.path

            // Safety: block system-protected paths
            if protectedPrefixes.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) {
                errors.append(DeletionError(url: item.url, message: "시스템 보호 경로입니다"))
                continue
            }

            do {
                try FileManager.default.removeItem(at: item.url)
                deletedCount += 1
                freedSize += item.size
            } catch {
                errors.append(DeletionError(url: item.url, message: error.localizedDescription))
            }
        }

        return DeletionResult(
            deletedCount: deletedCount,
            freedSize: freedSize,
            errors: errors
        )
    }
}
