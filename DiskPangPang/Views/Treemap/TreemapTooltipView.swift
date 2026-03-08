import SwiftUI

struct TreemapTooltipView: View {
    let node: FileNode
    let position: CGPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(node.name)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            HStack(spacing: 8) {
                let cat = node.isDirectory ? node.dominantCategory : node.category
                Circle()
                    .fill(cat.color)
                    .frame(width: 8, height: 8)
                Text(cat.label)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(node.totalSize.formattedSize)
                .font(AppTheme.monoFont)
                .foregroundStyle(AppTheme.textPrimary)

            if node.isDirectory {
                Text("\(node.children.count)개 항목")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text(node.url.path)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .padding(10)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .position(x: position.x + 120, y: position.y - 40)
        .allowsHitTesting(false)
    }
}
