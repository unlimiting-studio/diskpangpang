import Foundation
import os

struct ScanProgress: Sendable {
    let scannedCount: Int
    let currentPath: String
    let scannedSize: UInt64
    let estimatedTotalSize: UInt64

    var percentage: Double {
        guard estimatedTotalSize > 0 else { return 0 }
        return min(Double(scannedSize) / Double(estimatedTotalSize) * 100, 99.9)
    }
}

final class DiskScanner: Sendable {
    private let _isCancelled = OSAllocatedUnfairLock(initialState: false)

    var isCancelled: Bool {
        _isCancelled.withLock { $0 }
    }

    func cancel() {
        _isCancelled.withLock { $0 = true }
    }

    /// Runs synchronously on the caller's thread — call from a background Task.
    func scan(
        url: URL,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) -> FileNode {
        _isCancelled.withLock { $0 = false }

        let estimatedTotalSize = Self.estimateTotalSize(for: url)

        let root = FileNode(
            name: url.lastPathComponent,
            url: url,
            isDirectory: true
        )

        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .isDirectoryKey,
            .isHiddenKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsPackageDescendants]
        ) else {
            return root
        }

        var nodeMap: [String: FileNode] = [url.path: root]
        var scannedCount = 0
        var scannedSize: UInt64 = 0

        for case let fileURL as URL in enumerator {
            if isCancelled { break }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys) else {
                continue
            }

            if resourceValues.isSymbolicLink == true {
                if resourceValues.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            let isDirectory = resourceValues.isDirectory ?? false
            let isHidden = resourceValues.isHidden ?? false
            let fileSize = UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)

            let node = FileNode(
                name: fileURL.lastPathComponent,
                url: fileURL,
                isDirectory: isDirectory,
                isHidden: isHidden,
                fileSize: isDirectory ? 0 : fileSize
            )

            let parentPath = fileURL.deletingLastPathComponent().path
            if let parentNode = nodeMap[parentPath] {
                parentNode.addChild(node)
            }

            if isDirectory {
                nodeMap[fileURL.path] = node
            } else {
                scannedSize += fileSize
            }

            scannedCount += 1
            if scannedCount % 200 == 0 {
                onProgress(ScanProgress(
                    scannedCount: scannedCount,
                    currentPath: fileURL.lastPathComponent,
                    scannedSize: scannedSize,
                    estimatedTotalSize: estimatedTotalSize
                ))
                // Yield to let MainActor process UI updates
                Thread.sleep(forTimeInterval: 0.001)
            }
        }

        rollupSizes(node: root)
        return root
    }

    private static func estimateTotalSize(for url: URL) -> UInt64 {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]
        if let values = try? url.resourceValues(forKeys: keys),
           let total = values.volumeTotalCapacity,
           let available = values.volumeAvailableCapacity {
            return UInt64(max(total - available, 0))
        }
        return 0
    }

    private func rollupSizes(node: FileNode) {
        guard node.isDirectory else { return }

        var total: UInt64 = 0
        for child in node.children {
            if child.isDirectory {
                rollupSizes(node: child)
            }
            total += child.totalSize
        }
        node.totalSize = total
    }
}
