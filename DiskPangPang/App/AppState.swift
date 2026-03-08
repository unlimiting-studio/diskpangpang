import SwiftUI

@Observable
@MainActor
final class AppState {
    let scannerVM = ScannerViewModel()
    let treemapVM = TreemapViewModel()
    let collectorVM = CollectorViewModel()

    var hasFullDiskAccess = false
    var showPermissionAlert = false

    init() {
        checkPermissions()
    }

    func checkPermissions() {
        hasFullDiskAccess = PermissionService.hasFullDiskAccess
    }

    func onScanCompleted() {
        guard let root = scannerVM.rootNode else { return }
        treemapVM.setRoot(root)
    }
}
