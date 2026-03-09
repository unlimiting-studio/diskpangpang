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
    // 최상위 시스템 경로만 보호 (하위 항목은 삭제 허용)
    private let protectedExactPaths: Set<String> = [
        "/", "/System", "/usr", "/bin", "/sbin", "/dev", "/cores",
        "/Library", "/private", "/etc", "/tmp", "/var"
    ]

    func delete(items: [CollectorItem]) -> DeletionResult {
        // Sort by path depth descending (delete deepest first)
        let sorted = items.sorted { $0.url.pathComponents.count > $1.url.pathComponents.count }

        var deletedCount = 0
        var freedSize: UInt64 = 0
        var errors: [DeletionError] = []

        for item in sorted {
            let path = item.url.path

            // Safety: 최상위 시스템 디렉토리 자체의 삭제만 차단
            if protectedExactPaths.contains(path) {
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
