import SwiftUI

struct TreemapContainerView: View {
    @Bindable var treemapVM: TreemapViewModel
    @Bindable var collectorVM: CollectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            if !treemapVM.breadcrumbs.isEmpty {
                BreadcrumbBar(
                    breadcrumbs: treemapVM.breadcrumbs,
                    canGoUp: treemapVM.canGoUp,
                    onNavigate: { node in
                        treemapVM.zoomOut(to: node)
                    },
                    onGoUp: {
                        treemapVM.goUp()
                    }
                )
            }

            GeometryReader { geometry in
                TreemapCanvasLayer(
                    treemapVM: treemapVM,
                    collectorVM: collectorVM,
                    size: geometry.size
                )
            }
            .background(AppTheme.background)
        }
    }
}

/// Separate view to isolate state and prevent render loops
private struct TreemapCanvasLayer: View {
    @Bindable var treemapVM: TreemapViewModel
    @Bindable var collectorVM: CollectorViewModel
    let size: CGSize

    @State private var rects: [TreemapRect] = []
    @State private var hoveredNodeId: UUID?
    @State private var tooltipPos: CGPoint = .zero

    var body: some View {
        ZStack {
            // Canvas - only redraws when rects or hoveredNodeId change
            Canvas { context, canvasSize in
                for treemapRect in rects {
                    drawRect(treemapRect, in: &context)
                }
            }

            // Single gesture overlay
            Color.clear
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        tooltipPos = location
                        let node = hitTest(location)
                        let newId = node?.id
                        if newId != hoveredNodeId {
                            hoveredNodeId = newId
                            treemapVM.hoveredNode = node
                        }
                    case .ended:
                        hoveredNodeId = nil
                        treemapVM.hoveredNode = nil
                    }
                }
                .simultaneousGesture(
                    TapGesture()
                        .modifiers(.command)
                        .onEnded {
                            if let node = hitTest(tooltipPos) {
                                collectorVM.addItem(from: node)
                            }
                        }
                )
                .onTapGesture { location in
                    if let node = hitTest(location), node.isDirectory {
                        treemapVM.zoomIn(to: node)
                    }
                }

            // Context menu overlays - limited to top items only
            ForEach(Array(rects.prefix(60).filter { $0.width > 24 && $0.height > 24 }), id: \.node.id) { treemapRect in
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: treemapRect.width, height: treemapRect.height)
                    .position(
                        x: treemapRect.x + treemapRect.width / 2,
                        y: treemapRect.y + treemapRect.height / 2
                    )
                    .contextMenu {
                        Button {
                            collectorVM.addItem(from: treemapRect.node)
                        } label: {
                            Label("Collector에 추가", systemImage: "tray.and.arrow.down")
                        }
                        if treemapRect.node.isDirectory {
                            Button {
                                treemapVM.zoomIn(to: treemapRect.node)
                            } label: {
                                Label("이 폴더로 이동", systemImage: "arrow.right.circle")
                            }
                        }
                        Divider()
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([treemapRect.node.url])
                        } label: {
                            Label("Finder에서 보기", systemImage: "folder")
                        }
                    }
            }

            // Tooltip
            if hoveredNodeId != nil, let hovered = treemapVM.hoveredNode {
                TreemapTooltipView(node: hovered, position: tooltipPos)
            }
        }
        .onChange(of: treemapVM.currentNode?.id) { _, _ in
            recomputeRects()
        }
        .onChange(of: size) { _, _ in
            recomputeRects()
        }
        .onAppear {
            recomputeRects()
        }
    }

    private func recomputeRects() {
        rects = TreemapLayout.layout(
            nodes: treemapVM.displayChildren,
            in: CGRect(origin: .zero, size: size)
        )
    }

    private func hitTest(_ point: CGPoint) -> FileNode? {
        for r in rects {
            if r.cgRect.contains(point) {
                return r.node
            }
        }
        return nil
    }

    private func drawRect(_ treemapRect: TreemapRect, in context: inout GraphicsContext) {
        let rect = treemapRect.cgRect
        let isHovered = treemapRect.node.id == hoveredNodeId

        let category = treemapRect.node.isDirectory
            ? treemapRect.node.dominantCategory
            : treemapRect.node.category
        let baseColor = category.color
        let fillColor = isHovered ? baseColor.opacity(0.9) : baseColor.opacity(0.7)

        let path = RoundedRectangle(cornerRadius: 3).path(in: rect)
        context.fill(path, with: .color(fillColor))

        if isHovered {
            context.stroke(path, with: .color(.white.opacity(0.5)), lineWidth: 2)
        } else {
            context.stroke(path, with: .color(.black.opacity(0.3)), lineWidth: 0.5)
        }

        if rect.width > 50 && rect.height > 24 {
            let name = treemapRect.node.name
            let displayName = name.count > 20 ? String(name.prefix(18)) + "…" : name
            let textRect = CGRect(x: rect.minX + 6, y: rect.minY + 4, width: rect.width - 12, height: 16)
            context.draw(
                Text(displayName)
                    .font(.system(size: min(11, rect.height * 0.4), weight: .medium))
                    .foregroundStyle(.white),
                in: textRect
            )
            if rect.height > 40 {
                let sizeRect = CGRect(x: rect.minX + 6, y: rect.minY + 20, width: rect.width - 12, height: 14)
                context.draw(
                    Text(treemapRect.node.totalSize.formattedSize)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7)),
                    in: sizeRect
                )
            }
        }
    }
}
