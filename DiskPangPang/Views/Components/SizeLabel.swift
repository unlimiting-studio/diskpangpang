import SwiftUI

struct SizeLabel: View {
    let size: UInt64
    var font: Font = AppTheme.captionFont

    var body: some View {
        Text(size.formattedSize)
            .font(font)
            .foregroundStyle(AppTheme.textSecondary)
            .monospacedDigit()
    }
}
