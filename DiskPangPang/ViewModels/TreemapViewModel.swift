import Foundation
import SwiftUI

@Observable
@MainActor
final class TreemapViewModel {
    var zoomStack: [FileNode] = []
    var hoveredNode: FileNode?
    var tooltipPosition: CGPoint = .zero

    var currentNode: FileNode? {
        zoomStack.last
    }

    var displayChildren: [FileNode] {
        guard let current = currentNode else { return [] }
        return current.sortedChildren().filter { $0.totalSize > 0 }
    }

    func setRoot(_ node: FileNode) {
        zoomStack = [node]
        hoveredNode = nil
    }

    func zoomIn(to node: FileNode) {
        guard node.isDirectory, !node.children.isEmpty else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
            zoomStack.append(node)
            hoveredNode = nil
        }
    }

    func zoomOut(to node: FileNode) {
        guard let index = zoomStack.firstIndex(of: node) else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
            zoomStack = Array(zoomStack.prefix(through: index))
            hoveredNode = nil
        }
    }

    func goUp() {
        guard zoomStack.count > 1 else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
            zoomStack.removeLast()
            hoveredNode = nil
        }
    }

    var breadcrumbs: [FileNode] {
        zoomStack
    }

    var canGoUp: Bool {
        zoomStack.count > 1
    }
}
