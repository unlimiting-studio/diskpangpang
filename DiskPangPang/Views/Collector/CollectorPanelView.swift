import SwiftUI

struct CollectorPanelView: View {
    @Bindable var viewModel: CollectorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            if viewModel.isExpanded {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    itemsList
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private var headerBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isExpanded.toggle()
                }
            } label: {
                Image(systemName: viewModel.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .buttonStyle(.plain)

            Image(systemName: "tray.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.accent)

            Text("Collector")
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.textPrimary)

            if !viewModel.isEmpty {
                Text("\(viewModel.items.count)개")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.surfaceLight, in: Capsule())

                Spacer()

                SizeLabel(size: viewModel.totalSize, font: AppTheme.headlineFont)

                Button {
                    viewModel.clearAll()
                } label: {
                    Text("비우기")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.confirmDelete()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                        Text("삭제")
                    }
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(AppTheme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.surfaceLight.opacity(0.5))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("항목을 우클릭하여 Collector에 추가하세요")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
    }

    private var itemsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.items) { item in
                    CollectorItemChip(item: item) {
                        viewModel.removeItem(item)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 60)
    }
}

struct CollectorItemChip: View {
    let item: CollectorItem
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(item.category.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(item.size.formattedSize)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppTheme.surfaceLight, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
