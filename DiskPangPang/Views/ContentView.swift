import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        HSplitView {
            // Sidebar
            sidebar
                .frame(width: AppTheme.sidebarWidth)

            // Main content
            VStack(spacing: 0) {
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Collector panel
                CollectorPanelView(viewModel: appState.collectorVM)
            }
        }
        .background(AppTheme.background)
        .preferredColorScheme(.dark)
        .sheet(isPresented: Bindable(appState.collectorVM).showDeleteConfirmation) {
            DeleteConfirmationView(viewModel: appState.collectorVM)
        }
        .alert("삭제 결과", isPresented: Bindable(appState.collectorVM).showResult) {
            Button("확인", role: .cancel) {}
        } message: {
            if let result = appState.collectorVM.lastResult {
                Text(deletionResultMessage(result))
            }
        }
        .alert("Full Disk Access 필요", isPresented: $appState.showPermissionAlert) {
            Button("설정 열기") {
                PermissionService.openSystemPreferences()
            }
            Button("나중에", role: .cancel) {}
        } message: {
            Text("숨김 폴더 및 시스템 파일을 스캔하려면\nFull Disk Access 권한이 필요합니다.")
        }
        .onChange(of: appState.scannerVM.state) { _, newState in
            if case .completed = newState {
                appState.onScanCompleted()
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App title
            HStack {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.accent)
                Text("DiskPangPang")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(16)

            Divider()
                .background(AppTheme.border)

            DiskSelectorView(viewModel: appState.scannerVM)

            ScanProgressView(state: appState.scannerVM.state)

            Divider()
                .background(AppTheme.border)
                .padding(.vertical, 8)

            // Category legend
            categoryLegend

            Spacer()

            // Permission indicator
            permissionIndicator
        }
        .background(AppTheme.surface)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch appState.scannerVM.state {
        case .idle:
            VStack(spacing: 16) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.textTertiary)
                Text("스캔을 시작하세요")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("좌측에서 디스크를 선택하고\n스캔 버튼을 누르세요")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)

        case .scanning:
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppTheme.accent)
                Text("디스크 스캔 중...")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)

        case .completed:
            TreemapContainerView(
                treemapVM: appState.treemapVM,
                collectorVM: appState.collectorVM
            )

        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
                Text("스캔 오류")
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(message)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
        }
    }

    private var categoryLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("카테고리")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.bottom, 2)

            ForEach(FileCategory.allCases, id: \.self) { category in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(category.color)
                        .frame(width: 12, height: 12)

                    Text(category.label)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var permissionIndicator: some View {
        Button {
            if !appState.hasFullDiskAccess {
                appState.showPermissionAlert = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: appState.hasFullDiskAccess ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 10))
                Text(appState.hasFullDiskAccess ? "Full Access" : "제한된 접근")
                    .font(AppTheme.captionFont)
            }
            .foregroundStyle(appState.hasFullDiskAccess ? .green : .orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func deletionResultMessage(_ result: DeletionResult) -> String {
        var msg = "\(result.deletedCount)개 항목 삭제 완료\n"
        msg += "확보된 공간: \(result.freedSize.formattedSize)"
        if !result.errors.isEmpty {
            msg += "\n\(result.errors.count)개 항목 삭제 실패"
        }
        return msg
    }
}
