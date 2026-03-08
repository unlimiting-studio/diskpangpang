import SwiftUI

struct TreemapCanvasView: View {
    let rects: [TreemapRect]
    let hoveredNode: FileNode?

    var body: some View {
        Canvas { context, size in
            for treemapRect in rects {
                let rect = treemapRect.cgRect
                let isHovered = treemapRect.node.id == hoveredNode?.id

                // Background fill
                let category = treemapRect.node.isDirectory
                    ? treemapRect.node.dominantCategory
                    : treemapRect.node.category
                let baseColor = category.color
                let fillColor = isHovered
                    ? baseColor.opacity(0.9)
                    : baseColor.opacity(0.7)

                let path = RoundedRectangle(cornerRadius: 3)
                    .path(in: rect)

                context.fill(path, with: .color(fillColor))

                // Border
                if isHovered {
                    context.stroke(path, with: .color(.white.opacity(0.5)), lineWidth: 2)
                } else {
                    context.stroke(path, with: .color(.black.opacity(0.3)), lineWidth: 0.5)
                }

                // Label (only if rect is big enough)
                if rect.width > 50 && rect.height > 24 {
                    let name = treemapRect.node.name
                    let displayName = name.count > 20 ? String(name.prefix(18)) + "…" : name

                    let textRect = CGRect(
                        x: rect.minX + 6,
                        y: rect.minY + 4,
                        width: rect.width - 12,
                        height: 16
                    )

                    context.draw(
                        Text(displayName)
                            .font(.system(size: min(11, rect.height * 0.4), weight: .medium))
                            .foregroundStyle(.white),
                        in: textRect
                    )

                    // Size label
                    if rect.height > 40 {
                        let sizeRect = CGRect(
                            x: rect.minX + 6,
                            y: rect.minY + 20,
                            width: rect.width - 12,
                            height: 14
                        )
                        context.draw(
                            Text(treemapRect.node.totalSize.formattedSize)
                                .font(.system(size: 9, weight: .regular))
                                .foregroundStyle(.white.opacity(0.7)),
                            in: sizeRect
                        )
                    }
                }
            }
        }
    }
}
