import SwiftUI

enum AppTheme {
    // MARK: - Background
    static let background = Color(hex: 0x0D0D1A)
    static let surface = Color(hex: 0x161628)
    static let surfaceLight = Color(hex: 0x1E1E3A)

    // MARK: - Accent
    static let accent = Color(hex: 0xFF3B5C)
    static let accentHover = Color(hex: 0xFF5575)

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)

    // MARK: - Border
    static let border = Color.white.opacity(0.08)
    static let borderHover = Color.white.opacity(0.2)

    // MARK: - Typography
    static let titleFont: Font = .system(size: 22, weight: .bold)
    static let headlineFont: Font = .system(size: 15, weight: .semibold)
    static let bodyFont: Font = .system(size: 14, weight: .regular)
    static let captionFont: Font = .system(size: 13, weight: .regular)
    static let monoFont: Font = .system(size: 13, weight: .regular, design: .monospaced)

    // MARK: - Dimensions
    static let sidebarWidth: CGFloat = 220
    static let collectorHeight: CGFloat = 160
    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 4
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
