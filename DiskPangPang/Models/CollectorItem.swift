import Foundation

struct CollectorItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let url: URL
    let size: UInt64
    let isDirectory: Bool
    let category: FileCategory

    init(from node: FileNode) {
        self.id = node.id
        self.name = node.name
        self.url = node.url
        self.size = node.totalSize
        self.isDirectory = node.isDirectory
        self.category = node.isDirectory ? node.dominantCategory : node.category
    }
}
