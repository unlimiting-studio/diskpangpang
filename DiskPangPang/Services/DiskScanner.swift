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

        // Phase 1: Scan top-level directories in parallel
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey, .isDirectoryKey, .isHiddenKey,
            .isSymbolicLinkKey, .totalFileAllocatedSizeKey
        ]

        let topContents: [URL]
        do {
            topContents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: []
            )
        } catch {
            return root
        }

        // Create top-level nodes
        var topDirs: [(FileNode, URL)] = []
        for fileURL in topContents {
            if isCancelled { break }
            guard let rv = try? fileURL.resourceValues(forKeys: resourceKeys) else { continue }
            if rv.isSymbolicLink == true { continue }

            let isDir = rv.isDirectory ?? false
            let isHidden = rv.isHidden ?? false
            let fileSize = UInt64(rv.totalFileAllocatedSize ?? rv.fileSize ?? 0)

            let node = FileNode(
                name: fileURL.lastPathComponent,
                url: fileURL,
                isDirectory: isDir,
                isHidden: isHidden,
                fileSize: isDir ? 0 : fileSize
            )
            root.addChild(node)
            if isDir {
                topDirs.append((node, fileURL))
            }
        }

        // Phase 2: Scan each top-level directory in parallel
        let scannedSize = OSAllocatedUnfairLock(initialState: UInt64(0))
        let scannedCount = OSAllocatedUnfairLock(initialState: 0)
        let lastReportTime = OSAllocatedUnfairLock(initialState: CFAbsoluteTimeGetCurrent())

        let group = DispatchGroup()
        let concurrency = min(topDirs.count, 8)
        let queue = DispatchQueue(label: "scanner", attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: concurrency)

        for (dirNode, dirURL) in topDirs {
            if isCancelled { break }
            group.enter()
            semaphore.wait()

            queue.async { [self] in
                defer {
                    semaphore.signal()
                    group.leave()
                }

                self.scanDirectory(
                    dirNode: dirNode,
                    dirURL: dirURL,
                    resourceKeys: resourceKeys,
                    scannedSize: scannedSize,
                    scannedCount: scannedCount,
                    estimatedTotalSize: estimatedTotalSize,
                    lastReportTime: lastReportTime,
                    onProgress: onProgress
                )
            }
        }

        group.wait()

        // 스캔 완료 → 정리 중 표시
        let finalCount = scannedCount.withLock { $0 }
        let finalSize = scannedSize.withLock { $0 }
        onProgress(ScanProgress(
            scannedCount: finalCount,
            currentPath: "크기 계산 중…",
            scannedSize: finalSize,
            estimatedTotalSize: estimatedTotalSize
        ))

        // Rollup sizes + dominantCategory
        rollupSizes(node: root)
        return root
    }

    private func scanDirectory(
        dirNode: FileNode,
        dirURL: URL,
        resourceKeys: Set<URLResourceKey>,
        scannedSize: OSAllocatedUnfairLock<UInt64>,
        scannedCount: OSAllocatedUnfairLock<Int>,
        estimatedTotalSize: UInt64,
        lastReportTime: OSAllocatedUnfairLock<CFAbsoluteTime>,
        onProgress: @Sendable @escaping (ScanProgress) -> Void
    ) {
        guard let enumerator = FileManager.default.enumerator(
            at: dirURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsPackageDescendants]
        ) else { return }

        var nodeMap: [String: FileNode] = [dirURL.path: dirNode]
        var localCount = 0

        for case let fileURL as URL in enumerator {
            if isCancelled { break }

            guard let rv = try? fileURL.resourceValues(forKeys: resourceKeys) else { continue }

            if rv.isSymbolicLink == true {
                if rv.isDirectory == true { enumerator.skipDescendants() }
                continue
            }

            let isDir = rv.isDirectory ?? false
            let isHidden = rv.isHidden ?? false
            let fileSize = UInt64(rv.totalFileAllocatedSize ?? rv.fileSize ?? 0)

            let node = FileNode(
                name: fileURL.lastPathComponent,
                url: fileURL,
                isDirectory: isDir,
                isHidden: isHidden,
                fileSize: isDir ? 0 : fileSize
            )

            let parentPath = fileURL.deletingLastPathComponent().path
            if let parentNode = nodeMap[parentPath] {
                parentNode.addChild(node)
            }

            if isDir {
                nodeMap[fileURL.path] = node
            } else {
                scannedSize.withLock { $0 += fileSize }
            }

            localCount += 1
            if localCount % 500 == 0 {
                let batch = localCount
                localCount = 0
                let count = scannedCount.withLock { $0 += batch; return $0 }

                // Throttle progress reports to max 10/sec
                let now = CFAbsoluteTimeGetCurrent()
                let shouldReport = lastReportTime.withLock { last -> Bool in
                    if now - last >= 0.1 {
                        last = now
                        return true
                    }
                    return false
                }

                if shouldReport {
                    let size = scannedSize.withLock { $0 }
                    onProgress(ScanProgress(
                        scannedCount: count,
                        currentPath: fileURL.lastPathComponent,
                        scannedSize: size,
                        estimatedTotalSize: estimatedTotalSize
                    ))
                }
            }
        }

        // Flush remaining count
        if localCount > 0 {
            let remaining = localCount
            scannedCount.withLock { $0 += remaining }
        }
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
        var categorySizes: [FileCategory: UInt64] = [:]
        for child in node.children {
            if child.isDirectory { rollupSizes(node: child) }
            total += child.totalSize
            let cat = child.isDirectory ? child.dominantCategory : child.category
            categorySizes[cat, default: 0] += child.totalSize
        }
        node.totalSize = total
        node.dominantCategory = categorySizes.max(by: { $0.value < $1.value })?.key ?? .other
    }
}
