import SwiftUI

struct TreemapTooltipView: View {
    let node: FileNode
    let position: CGPoint
    let containerSize: CGSize

    private let tipWidth: CGFloat = 220
    private let tipHeight: CGFloat = 90
    private let gap: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(node.name)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            HStack(spacing: 6) {
                let cat = node.isDirectory ? node.dominantCategory : node.category
                Circle()
                    .fill(cat.color)
                    .frame(width: 8, height: 8)
                Text(cat.label)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Text(node.totalSize.formattedSize)
                    .font(AppTheme.monoFont)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            if node.isDirectory {
                Text("\(node.children.count)개 항목")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(width: tipWidth, alignment: .leading)
        .padding(10)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .fixedSize(horizontal: false, vertical: true)
        .position(x: anchorX, y: anchorY)
        .allowsHitTesting(false)
    }

    private var anchorX: CGFloat {
        let rightX = position.x + gap + tipWidth / 2
        if rightX + tipWidth / 2 + 8 > containerSize.width {
            return position.x - gap - tipWidth / 2
        }
        return rightX
    }

    private var anchorY: CGFloat {
        let aboveY = position.y - gap - tipHeight / 2
        if aboveY - tipHeight / 2 < 0 {
            return position.y + gap + tipHeight / 2
        }
        return aboveY
    }
}
