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

    private let maxDisplayItems = 150
    private(set) var displayChildren: [FileNode] = []

    private func updateDisplayChildren() {
        guard let current = currentNode else {
            displayChildren = []
            return
        }
        let all = current.sortedChildren().filter { $0.totalSize > 0 }
        displayChildren = all.count <= maxDisplayItems ? all : Array(all.prefix(maxDisplayItems))
    }

    func setRoot(_ node: FileNode) {
        zoomStack = [node]
        hoveredNode = nil
        updateDisplayChildren()
    }

    func zoomIn(to node: FileNode) {
        guard node.isDirectory, !node.children.isEmpty else { return }
        zoomStack.append(node)
        hoveredNode = nil
        updateDisplayChildren()
    }

    func zoomOut(to node: FileNode) {
        guard let index = zoomStack.firstIndex(of: node) else { return }
        zoomStack = Array(zoomStack.prefix(through: index))
        hoveredNode = nil
        updateDisplayChildren()
    }

    func goUp() {
        guard zoomStack.count > 1 else { return }
        zoomStack.removeLast()
        hoveredNode = nil
        updateDisplayChildren()
    }

    var breadcrumbs: [FileNode] {
        zoomStack
    }

    var canGoUp: Bool {
        zoomStack.count > 1
    }
}
