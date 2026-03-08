import Foundation
import SwiftUI

enum ScanState: Equatable {
    case idle
    case scanning(progress: ScanProgress)
    case completed
    case error(String)

    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.completed, .completed): true
        case (.scanning(let a), .scanning(let b)): a == b
        case (.error(let a), .error(let b)): a == b
        default: false
        }
    }
}

extension ScanProgress: Equatable {
    static func == (lhs: ScanProgress, rhs: ScanProgress) -> Bool {
        lhs.scannedCount == rhs.scannedCount
    }
}

@Observable
@MainActor
final class ScannerViewModel {
    var state: ScanState = .idle
    var rootNode: FileNode?
    var selectedVolume: URL = URL(fileURLWithPath: "/")
    var availableVolumes: [URL] = []

    private let scanner = DiskScanner()
    private var scanTask: Task<Void, Never>?

    init() {
        loadVolumes()
    }

    func loadVolumes() {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey]
        guard let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return }

        // 루트 볼륨(/)을 반드시 포함, 외장 디스크도 포함
        var result: [URL] = []
        let hasRoot = volumes.contains { $0.path == "/" }
        if hasRoot {
            result.append(URL(fileURLWithPath: "/"))
        }
        for vol in volumes where vol.path != "/" {
            result.append(vol)
        }
        availableVolumes = result
        if let first = result.first {
            selectedVolume = first
        }
    }

    func startScan() {
        scanTask?.cancel()
        state = .scanning(progress: ScanProgress(scannedCount: 0, currentPath: "", scannedSize: 0, estimatedTotalSize: 0))
        rootNode = nil

        let url = selectedVolume
        let scannerRef = scanner

        scanTask = Task.detached(priority: .userInitiated) { @Sendable [weak self] in
            nonisolated(unsafe) let weakSelf = self
            let result = scannerRef.scan(url: url) { progress in
                DispatchQueue.main.async {
                    weakSelf?.state = .scanning(progress: progress)
                }
            }

            DispatchQueue.main.async {
                guard !Task.isCancelled else { return }
                weakSelf?.rootNode = result
                weakSelf?.state = .completed
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanner.cancel()
        state = .idle
    }
}
