import SwiftUI

struct BreadcrumbBar: View {
    let breadcrumbs: [FileNode]
    let canGoUp: Bool
    let onNavigate: (FileNode) -> Void
    let onGoUp: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            // 뒤로가기 버튼
            Button {
                onGoUp()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(canGoUp ? AppTheme.accent : AppTheme.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(canGoUp ? AppTheme.surfaceLight : Color.clear, in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .disabled(!canGoUp)

            ForEach(Array(breadcrumbs.enumerated()), id: \.element.id) { index, node in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Button {
                    onNavigate(node)
                } label: {
                    Text(node.name)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(
                            index == breadcrumbs.count - 1
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary
                        )
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            index == breadcrumbs.count - 1
                                ? AppTheme.surfaceLight
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: AppTheme.smallCornerRadius)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.surface)
    }
}
