import Foundation

/// Serializable representation of FileNode for disk cache
private struct CachedNode: Codable {
    let name: String
    let path: String
    let isDirectory: Bool
    let isHidden: Bool
    let fileSize: UInt64
    let totalSize: UInt64
    let dominantCategory: FileCategory
    let children: [CachedNode]

    init(name: String, path: String, isDirectory: Bool, isHidden: Bool,
         fileSize: UInt64, totalSize: UInt64, dominantCategory: FileCategory, children: [CachedNode]) {
        self.name = name; self.path = path; self.isDirectory = isDirectory
        self.isHidden = isHidden; self.fileSize = fileSize; self.totalSize = totalSize
        self.dominantCategory = dominantCategory; self.children = children
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        path = try c.decode(String.self, forKey: .path)
        isDirectory = try c.decode(Bool.self, forKey: .isDirectory)
        isHidden = try c.decode(Bool.self, forKey: .isHidden)
        fileSize = try c.decode(UInt64.self, forKey: .fileSize)
        totalSize = try c.decode(UInt64.self, forKey: .totalSize)
        dominantCategory = (try? c.decode(FileCategory.self, forKey: .dominantCategory)) ?? .other
        children = try c.decode([CachedNode].self, forKey: .children)
    }
}

enum ScanCache {
    private static var cacheDir: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.unlimiting.diskpangpang", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func cacheFile(for volumePath: String) -> URL {
        let safeName = volumePath.replacingOccurrences(of: "/", with: "_")
        return cacheDir.appendingPathComponent("scan_\(safeName).json")
    }

    static func save(root: FileNode, volumePath: String) {
        let cached = toCache(root)
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(cached) else { return }
        try? data.write(to: cacheFile(for: volumePath), options: .atomic)
    }

    static func load(volumePath: String) -> FileNode? {
        let file = cacheFile(for: volumePath)
        guard let data = try? Data(contentsOf: file),
              let cached = try? JSONDecoder().decode(CachedNode.self, from: data) else {
            return nil
        }
        return fromCache(cached)
    }

    static func cacheDate(volumePath: String) -> Date? {
        let file = cacheFile(for: volumePath)
        return (try? FileManager.default.attributesOfItem(atPath: file.path))?[.modificationDate] as? Date
    }

    private static func toCache(_ node: FileNode) -> CachedNode {
        CachedNode(
            name: node.name,
            path: node.url.path,
            isDirectory: node.isDirectory,
            isHidden: node.isHidden,
            fileSize: node.fileSize,
            totalSize: node.totalSize,
            dominantCategory: node.dominantCategory,
            children: node.children.map { toCache($0) }
        )
    }

    private static func fromCache(_ cached: CachedNode) -> FileNode {
        let node = FileNode(
            name: cached.name,
            url: URL(fileURLWithPath: cached.path),
            isDirectory: cached.isDirectory,
            isHidden: cached.isHidden,
            fileSize: cached.isDirectory ? 0 : cached.fileSize
        )
        node.totalSize = cached.totalSize
        node.dominantCategory = cached.dominantCategory
        for child in cached.children {
            node.addChild(fromCache(child))
        }
        return node
    }
}
