import Foundation

struct TreemapRect: Sendable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let node: FileNode

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

enum TreemapLayout {
    /// Squarified treemap algorithm
    /// Reference: Bruls, Huizing, van Wijk (2000)
    static func layout(
        nodes: [FileNode],
        in rect: CGRect,
        padding: CGFloat = 2
    ) -> [TreemapRect] {
        guard !nodes.isEmpty, rect.width > 0, rect.height > 0 else { return [] }

        let totalSize = nodes.reduce(UInt64(0)) { $0 + $1.totalSize }
        guard totalSize > 0 else { return [] }

        let sorted = nodes.sorted { $0.totalSize > $1.totalSize }

        var results: [TreemapRect] = []
        var remaining = sorted.map { (node: $0, area: Double($0.totalSize) / Double(totalSize) * Double(rect.width * rect.height)) }
        var currentRect = rect

        while !remaining.isEmpty {
            let isWide = currentRect.width >= currentRect.height
            let side = isWide ? currentRect.height : currentRect.width

            var row: [(node: FileNode, area: Double)] = []
            var rowArea: Double = 0

            for item in remaining {
                let testRow = row + [item]
                let testArea = rowArea + item.area

                if row.isEmpty || worstAspect(testRow, side: side, totalArea: testArea)
                    <= worstAspect(row, side: side, totalArea: rowArea) {
                    row.append(item)
                    rowArea += item.area
                } else {
                    break
                }
            }

            remaining.removeFirst(row.count)

            // Lay out the row
            let rowLength = side > 0 ? CGFloat(rowArea) / side : 0
            var offset: CGFloat = 0

            for item in row {
                let itemLength = rowArea > 0 ? CGFloat(item.area) / rowLength : 0

                let itemRect: CGRect
                if isWide {
                    itemRect = CGRect(
                        x: currentRect.minX + padding / 2,
                        y: currentRect.minY + offset + padding / 2,
                        width: rowLength - padding,
                        height: itemLength - padding
                    )
                } else {
                    itemRect = CGRect(
                        x: currentRect.minX + offset + padding / 2,
                        y: currentRect.minY + padding / 2,
                        width: itemLength - padding,
                        height: rowLength - padding
                    )
                }

                if itemRect.width > 1 && itemRect.height > 1 {
                    results.append(TreemapRect(
                        x: itemRect.origin.x,
                        y: itemRect.origin.y,
                        width: itemRect.width,
                        height: itemRect.height,
                        node: item.node
                    ))
                }

                offset += itemLength
            }

            // Shrink remaining rect
            if isWide {
                currentRect = CGRect(
                    x: currentRect.minX + rowLength,
                    y: currentRect.minY,
                    width: currentRect.width - rowLength,
                    height: currentRect.height
                )
            } else {
                currentRect = CGRect(
                    x: currentRect.minX,
                    y: currentRect.minY + rowLength,
                    width: currentRect.width,
                    height: currentRect.height - rowLength
                )
            }
        }

        return results
    }

    private static func worstAspect(
        _ row: [(node: FileNode, area: Double)],
        side: CGFloat,
        totalArea: Double
    ) -> Double {
        guard !row.isEmpty, side > 0, totalArea > 0 else { return .infinity }

        let rowLength = totalArea / Double(side)
        guard rowLength > 0 else { return .infinity }

        var worst: Double = 0
        for item in row {
            let itemLength = item.area / rowLength
            let aspect = max(rowLength / itemLength, itemLength / rowLength)
            worst = max(worst, aspect)
        }
        return worst
    }
}
