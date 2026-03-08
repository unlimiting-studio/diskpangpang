import SwiftUI

@main
struct DiskPangPangApp: App {
    @State private var isLicensed = LicenseService.shared.isActivated

    var body: some Scene {
        WindowGroup {
            Group {
                if isLicensed {
                    ContentView()
                } else {
                    LicenseGateView {
                        isLicensed = true
                    }
                }
            }
            .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
    }
}
