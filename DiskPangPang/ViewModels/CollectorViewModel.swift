import Foundation
import SwiftUI

@Observable
@MainActor
final class CollectorViewModel {
    var items: [CollectorItem] = []
    var showDeleteConfirmation = false
    var isDeleting = false
    var lastResult: DeletionResult?
    var showResult = false
    var isExpanded = true

    private let deletionService = DeletionService()

    var totalSize: UInt64 {
        items.reduce(0) { $0 + $1.size }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    func addItem(from node: FileNode) {
        let item = CollectorItem(from: node)

        // Skip if already in collector
        guard !items.contains(where: { $0.url == item.url }) else { return }

        // If adding a directory, remove any children already in collector
        if node.isDirectory {
            items.removeAll { existing in
                existing.url.path.hasPrefix(node.url.path + "/")
            }
        }

        // If a parent directory is already in collector, skip
        let isChildOfExisting = items.contains { existing in
            existing.isDirectory && item.url.path.hasPrefix(existing.url.path + "/")
        }
        guard !isChildOfExisting else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            items.append(item)
        }
    }

    func removeItem(_ item: CollectorItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            items.removeAll { $0.id == item.id }
        }
    }

    func clearAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            items.removeAll()
        }
    }

    func confirmDelete() {
        showDeleteConfirmation = true
    }

    func executeDelete() {
        isDeleting = true
        let itemsToDelete = items

        Task {
            let result = await deletionService.delete(items: itemsToDelete)
            isDeleting = false
            lastResult = result
            showResult = true

            // Remove successfully deleted items
            let deletedURLs = Set(itemsToDelete.map(\.url))
                .subtracting(result.errors.map(\.url))
            withAnimation {
                items.removeAll { deletedURLs.contains($0.url) }
            }
        }
    }
}
