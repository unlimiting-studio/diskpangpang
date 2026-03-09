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
                    onNavigate: { treemapVM.zoomOut(to: $0) },
                    onGoUp: { treemapVM.goUp() }
                )
            }

            GeometryReader { geometry in
                let rects = TreemapLayout.layout(
                    nodes: treemapVM.displayChildren,
                    in: CGRect(origin: .zero, size: geometry.size)
                )

                TreemapCanvas(
                    rects: rects,
                    containerSize: geometry.size,
                    treemapVM: treemapVM,
                    collectorVM: collectorVM
                )
            }
            .background(AppTheme.background)
        }
    }
}

private struct TreemapCanvas: View {
    let rects: [TreemapRect]
    let containerSize: CGSize
    @Bindable var treemapVM: TreemapViewModel
    @Bindable var collectorVM: CollectorViewModel

    @State private var hoveredNodeId: UUID?
    @State private var mousePos: CGPoint = .zero

    var body: some View {
        ZStack {
            // Canvas
            Canvas { context, _ in
                for r in rects {
                    drawRect(r, in: &context)
                }
            }

            // 단일 제스처 레이어 (호버 + 클릭 + 우클릭 메뉴)
            Color.clear
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let pt):
                        mousePos = pt
                        let node = hitTest(pt)
                        if node?.id != hoveredNodeId {
                            hoveredNodeId = node?.id
                            treemapVM.hoveredNode = node
                        }
                    case .ended:
                        hoveredNodeId = nil
                        treemapVM.hoveredNode = nil
                    }
                }
                .onTapGesture { location in
                    if let node = hitTest(location), node.isDirectory {
                        treemapVM.zoomIn(to: node)
                    }
                }
                .simultaneousGesture(
                    TapGesture()
                        .modifiers(.command)
                        .onEnded {
                            if let node = hitTest(mousePos) {
                                collectorVM.addItem(from: node)
                            }
                        }
                )
                .contextMenu {
                    if let node = treemapVM.hoveredNode {
                        Button { collectorVM.addItem(from: node) } label: {
                            Label("Collector에 추가", systemImage: "tray.and.arrow.down")
                        }
                        if node.isDirectory {
                            Button { treemapVM.zoomIn(to: node) } label: {
                                Label("이 폴더로 이동", systemImage: "arrow.right.circle")
                            }
                        }
                        Divider()
                        Button { NSWorkspace.shared.activateFileViewerSelecting([node.url]) } label: {
                            Label("Finder에서 보기", systemImage: "folder")
                        }
                    }
                }

            // Tooltip
            if let hovered = treemapVM.hoveredNode {
                TreemapTooltipView(node: hovered, position: mousePos, containerSize: containerSize)
            }
        }
    }

    private func hitTest(_ pt: CGPoint) -> FileNode? {
        for r in rects where r.cgRect.contains(pt) { return r.node }
        return nil
    }

    private func drawRect(_ r: TreemapRect, in ctx: inout GraphicsContext) {
        let rect = r.cgRect
        let isHovered = r.node.id == hoveredNodeId
        let cat = r.node.isDirectory ? r.node.dominantCategory : r.node.category
        let fill = isHovered ? cat.color.opacity(0.9) : cat.color.opacity(0.7)
        let path = RoundedRectangle(cornerRadius: 3).path(in: rect)

        ctx.fill(path, with: .color(fill))
        ctx.stroke(path, with: .color(isHovered ? .white.opacity(0.5) : .black.opacity(0.3)),
                   lineWidth: isHovered ? 2 : 0.5)

        if rect.width > 50, rect.height > 24 {
            let name = r.node.name
            let fontSize = min(13, rect.height * 0.35)
            let availableW = rect.width - 12
            // 너비 기반 글자수 제한: 글자당 약 7pt 기준
            let maxChars = Int(availableW / (fontSize * 0.6))
            let label = name.count > maxChars ? String(name.prefix(max(maxChars - 1, 1))) + "…" : name
            ctx.draw(
                Text(label).font(.system(size: fontSize, weight: .medium)).foregroundStyle(.white),
                in: CGRect(x: rect.minX + 6, y: rect.minY + 4, width: availableW, height: 18)
            )
            if rect.height > 40 {
                ctx.draw(
                    Text(r.node.totalSize.formattedSize).font(.system(size: 11)).foregroundStyle(.white.opacity(0.7)),
                    in: CGRect(x: rect.minX + 6, y: rect.minY + 22, width: availableW, height: 16)
                )
            }
        }
    }
}
