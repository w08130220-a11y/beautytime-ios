import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ServiceCategory?
    @Binding var selectedCity: TaiwanCity?
    @Binding var selectedTags: Set<String>
    var onApply: () -> Void

    @State private var popularTags: [PopularTag] = []

    private let categoryColumns = [
        GridItem(.adaptive(minimum: 80), spacing: BTSpacing.sm)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BTSpacing.xl) {
                    // Style tags section
                    if !popularTags.isEmpty {
                        VStack(alignment: .leading, spacing: BTSpacing.md) {
                            Text("熱門風格")
                                .font(.headline)
                                .foregroundStyle(BTColor.textPrimary)

                            FlowLayout(spacing: BTSpacing.sm) {
                                ForEach(popularTags, id: \.tag) { tagItem in
                                    Button {
                                        if selectedTags.contains(tagItem.tag) {
                                            selectedTags.remove(tagItem.tag)
                                        } else {
                                            selectedTags.insert(tagItem.tag)
                                        }
                                    } label: {
                                        Text("#\(tagItem.tag)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, BTSpacing.md)
                                            .padding(.vertical, BTSpacing.sm)
                                            .background(
                                                selectedTags.contains(tagItem.tag)
                                                    ? BTColor.primary.opacity(0.15)
                                                    : BTColor.secondaryBackground
                                            )
                                            .foregroundStyle(
                                                selectedTags.contains(tagItem.tag)
                                                    ? BTColor.primary
                                                    : BTColor.textSecondary
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        selectedTags.contains(tagItem.tag)
                                                            ? BTColor.primary.opacity(0.3)
                                                            : Color.clear,
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Divider()
                            .foregroundStyle(BTColor.border)
                    }

                    // Category picker
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("服務類別")
                            .font(.headline)
                            .foregroundStyle(BTColor.textPrimary)

                        LazyVGrid(columns: categoryColumns, spacing: BTSpacing.sm) {
                            ForEach(ServiceCategory.allCases, id: \.self) { category in
                                FilterCategoryItem(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }

                    Divider()
                        .foregroundStyle(BTColor.border)

                    // City picker
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("城市")
                            .font(.headline)
                            .foregroundStyle(BTColor.textPrimary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: BTSpacing.sm)], spacing: BTSpacing.sm) {
                            ForEach(TaiwanCity.allCases, id: \.self) { city in
                                Button {
                                    if selectedCity == city {
                                        selectedCity = nil
                                    } else {
                                        selectedCity = city
                                    }
                                } label: {
                                    Text(city.displayName)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .padding(.horizontal, BTSpacing.sm)
                                        .padding(.vertical, BTSpacing.sm)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedCity == city ? BTColor.primary : BTColor.secondaryBackground)
                                        .foregroundStyle(selectedCity == city ? .white : BTColor.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(BTSpacing.lg)
            }
            .background(BTColor.background)
            .navigationTitle("篩選")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(BTColor.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: BTSpacing.md) {
                    Button {
                        selectedCategory = nil
                        selectedCity = nil
                        selectedTags.removeAll()
                        onApply()
                        dismiss()
                    } label: {
                        Text("清除")
                            .btSecondaryButton()
                    }

                    Button {
                        onApply()
                        dismiss()
                    } label: {
                        Text("套用")
                            .btPrimaryButton()
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
                .padding(.vertical, BTSpacing.md)
                .background(BTColor.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -2)
            }
            .task {
                await loadPopularTags()
            }
        }
    }

    private func loadPopularTags() async {
        do {
            popularTags = try await APIClient.shared.get(path: APIEndpoints.Providers.popularTags)
        } catch {
            // Silently fail
        }
    }
}

// MARK: - Filter Category Item

private struct FilterCategoryItem: View {
    let category: ServiceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: BTSpacing.sm) {
                Image(systemName: category.iconName)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? BTColor.primary : BTColor.secondaryBackground)
                    .foregroundStyle(isSelected ? .white : BTColor.primary)
                    .clipShape(Circle())
                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? BTColor.primary : BTColor.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return ArrangeResult(
            positions: positions,
            sizes: sizes,
            size: CGSize(width: maxWidth, height: currentY + rowHeight)
        )
    }

    private struct ArrangeResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize
    }
}

#Preview {
    FilterSheet(
        selectedCategory: .constant(.nail),
        selectedCity: .constant(.taipei),
        selectedTags: .constant(Set(["89風"]))
    ) {}
}
