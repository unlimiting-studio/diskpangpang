import SwiftUI

struct DeleteConfirmationView: View {
    @Bindable var viewModel: CollectorViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("영구 삭제 확인")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("\(viewModel.items.count)개 항목 (\(viewModel.totalSize.formattedSize))을\n영구적으로 삭제합니다.\n이 작업은 되돌릴 수 없습니다.")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            // Item preview
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.items) { item in
                        HStack {
                            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(item.category.color)
                            Text(item.name)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(item.size.formattedSize)
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 150)
            .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 6))

            HStack(spacing: 12) {
                Button("취소") {
                    viewModel.showDeleteConfirmation = false
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    viewModel.showDeleteConfirmation = false
                    viewModel.executeDelete()
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("영구 삭제")
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(AppTheme.surface)
    }
}
