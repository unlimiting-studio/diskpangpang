import Foundation

@Observable
final class FileNode: Identifiable, @unchecked Sendable {
    let id: UUID
    let name: String
    let url: URL
    let isDirectory: Bool
    let isHidden: Bool
    let category: FileCategory

    var fileSize: UInt64
    var totalSize: UInt64
    private(set) var children: [FileNode]

    weak var parent: FileNode?

    init(
        name: String,
        url: URL,
        isDirectory: Bool,
        isHidden: Bool = false,
        fileSize: UInt64 = 0
    ) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.isHidden = isHidden
        self.fileSize = fileSize
        self.totalSize = fileSize
        self.children = []

        if isDirectory {
            self.category = .other
        } else {
            self.category = FileCategory.categorize(extension: url.pathExtension)
        }
    }

    func addChild(_ child: FileNode) {
        child.parent = self
        children.append(child)
    }

    func sortedChildren() -> [FileNode] {
        children.sorted { $0.totalSize > $1.totalSize }
    }

    var depth: Int {
        var d = 0
        var current = parent
        while let p = current {
            d += 1
            current = p.parent
        }
        return d
    }

    var pathComponents: [FileNode] {
        var components: [FileNode] = [self]
        var current = parent
        while let p = current {
            components.insert(p, at: 0)
            current = p.parent
        }
        return components
    }

    var dominantCategory: FileCategory {
        if !isDirectory { return category }
        guard !children.isEmpty else { return .other }

        var categorySizes: [FileCategory: UInt64] = [:]
        for child in children {
            let cat = child.isDirectory ? child.dominantCategory : child.category
            categorySizes[cat, default: 0] += child.totalSize
        }
        return categorySizes.max(by: { $0.value < $1.value })?.key ?? .other
    }
}

extension FileNode: Hashable {
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
