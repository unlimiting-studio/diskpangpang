import SwiftUI

struct TreemapContainerView: View {
    @Bindable var treemapVM: TreemapViewModel
    @Bindable var collectorVM: CollectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb bar
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

            // Treemap canvas
            GeometryReader { geometry in
                let children = treemapVM.displayChildren
                let rects = TreemapLayout.layout(
                    nodes: children,
                    in: CGRect(origin: .zero, size: geometry.size)
                )

                ZStack {
                    // Canvas rendering
                    TreemapCanvasView(
                        rects: rects,
                        hoveredNode: treemapVM.hoveredNode
                    )

                    // Interaction overlay
                    ForEach(rects, id: \.node.id) { treemapRect in
                        Color.clear
                            .frame(
                                width: treemapRect.width,
                                height: treemapRect.height
                            )
                            .position(
                                x: treemapRect.x + treemapRect.width / 2,
                                y: treemapRect.y + treemapRect.height / 2
                            )
                            .onHover { isHovered in
                                treemapVM.hoveredNode = isHovered ? treemapRect.node : nil
                            }
                            .onTapGesture {
                                if treemapRect.node.isDirectory {
                                    treemapVM.zoomIn(to: treemapRect.node)
                                }
                            }
                            .contextMenu {
                                contextMenu(for: treemapRect.node)
                            }
                    }

                    // Tooltip
                    if let hovered = treemapVM.hoveredNode {
                        TreemapTooltipView(
                            node: hovered,
                            position: treemapVM.tooltipPosition
                        )
                    }
                }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        treemapVM.tooltipPosition = location
                    case .ended:
                        treemapVM.hoveredNode = nil
                    }
                }
            }
            .background(AppTheme.background)
        }
    }

    @ViewBuilder
    private func contextMenu(for node: FileNode) -> some View {
        Button {
            collectorVM.addItem(from: node)
        } label: {
            Label("Collector에 추가", systemImage: "tray.and.arrow.down")
        }

        if node.isDirectory {
            Button {
                treemapVM.zoomIn(to: node)
            } label: {
                Label("이 폴더로 이동", systemImage: "arrow.right.circle")
            }
        }

        Divider()

        Button {
            NSWorkspace.shared.activateFileViewerSelecting([node.url])
        } label: {
            Label("Finder에서 보기", systemImage: "folder")
        }
    }
}
