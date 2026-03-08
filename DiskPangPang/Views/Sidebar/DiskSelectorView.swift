import SwiftUI

struct DiskSelectorView: View {
    @Bindable var viewModel: ScannerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("디스크 선택")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.textPrimary)

            Menu {
                ForEach(viewModel.availableVolumes, id: \.self) { volume in
                    Button(volumeLabel(for: volume)) {
                        viewModel.selectedVolume = volume
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 12))
                    Text(volumeLabel(for: viewModel.selectedVolume))
                        .font(AppTheme.bodyFont)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(AppTheme.surfaceLight, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .buttonStyle(.plain)

            scanButton
        }
        .padding(16)
    }

    @ViewBuilder
    private var scanButton: some View {
        switch viewModel.state {
        case .idle, .completed, .error:
            Button {
                viewModel.startScan()
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("스캔 시작")
                }
                .font(AppTheme.headlineFont)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .buttonStyle(.plain)

        case .scanning:
            Button {
                viewModel.cancelScan()
            } label: {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                    Text("취소")
                }
                .font(AppTheme.headlineFont)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppTheme.surfaceLight, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
            .buttonStyle(.plain)
        }
    }

    private func volumeLabel(for url: URL) -> String {
        let keys: Set<URLResourceKey> = [.volumeNameKey, .volumeTotalCapacityKey]
        if let values = try? url.resourceValues(forKeys: keys),
           let name = values.volumeName {
            if let total = values.volumeTotalCapacity {
                let size = UInt64(total).formattedSize
                return "\(name) (\(size))"
            }
            return name
        }
        return url.lastPathComponent
    }
}
