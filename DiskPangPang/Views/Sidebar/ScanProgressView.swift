import SwiftUI

struct ScanProgressView: View {
    let state: ScanState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch state {
            case .idle:
                EmptyView()

            case .scanning(let progress):
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(AppTheme.accent)
                    Text("스캔 중...")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    if progress.estimatedTotalSize > 0 {
                        Text(String(format: "%.1f%%", progress.percentage))
                            .font(AppTheme.monoFont)
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                // Progress bar
                if progress.estimatedTotalSize > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.surfaceLight)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.accent)
                                .frame(
                                    width: geo.size.width * CGFloat(progress.percentage / 100),
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.3), value: progress.scannedCount)
                        }
                    }
                    .frame(height: 6)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AppTheme.accent)
                }

                Text("\(progress.scannedCount.formatted())개 항목")
                    .font(AppTheme.monoFont)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: 4) {
                    Text(progress.scannedSize.formattedSize)
                        .font(AppTheme.monoFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    if progress.estimatedTotalSize > 0 {
                        Text("/ \(progress.estimatedTotalSize.formattedSize)")
                            .font(AppTheme.monoFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }

                if !progress.currentPath.isEmpty {
                    Text(progress.currentPath)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

            case .completed:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("스캔 완료")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.textPrimary)
                }

            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("오류")
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Text(message)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
    }
}
