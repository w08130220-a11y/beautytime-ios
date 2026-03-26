import SwiftUI
import Kingfisher

struct PortfolioSection: View {
    let items: [PortfolioItem]
    @State private var selectedItem: PortfolioItem?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        if items.isEmpty {
            Text("尚無作品集")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 32)
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { item in
                    PortfolioCard(item: item)
                        .onTapGesture {
                            selectedItem = item
                        }
                }
            }
            .sheet(item: $selectedItem) { item in
                PortfolioDetailSheet(item: item)
                    .presentationDetents([.large])
            }
        }
    }
}

// MARK: - Portfolio Card

private struct PortfolioCard: View {
    let item: PortfolioItem

    var body: some View {
        VStack(spacing: 0) {
            // Before/After comparison
            ZStack(alignment: .bottomLeading) {
                HStack(spacing: 2) {
                    // Before
                    KFImage(URL(string: item.beforePhotoUrl ?? ""))
                        .placeholder {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay {
                                    Text("Before")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .clipped()

                    // After
                    KFImage(URL(string: item.afterPhotoUrl ?? ""))
                        .placeholder {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .overlay {
                                    Text("After")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .clipped()
                }

                // Label overlay
                HStack(spacing: 0) {
                    Text("前")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                    Text("後")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.7))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(4)
            }

            // Style tags
            if let tags = item.styleTags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Portfolio Detail Sheet

private struct PortfolioDetailSheet: View {
    let item: PortfolioItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Before
                    VStack(alignment: .leading, spacing: 4) {
                        Text("施作前")
                            .font(.subheadline.weight(.medium))
                        KFImage(URL(string: item.beforePhotoUrl ?? ""))
                            .placeholder {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 250)
                            }
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // After
                    VStack(alignment: .leading, spacing: 4) {
                        Text("施作後")
                            .font(.subheadline.weight(.medium))
                        KFImage(URL(string: item.afterPhotoUrl ?? ""))
                            .placeholder {
                                Rectangle()
                                    .fill(Color(.systemGray4))
                                    .frame(height: 250)
                            }
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Tags
                    if let tags = item.styleTags, !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("風格標籤")
                                .font(.subheadline.weight(.medium))
                            FlowLayout(spacing: 6) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Description
                    if let description = item.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("說明")
                                .font(.subheadline.weight(.medium))
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("作品詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout (iOS 16 compatible)

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
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

#Preview {
    PortfolioSection(items: [
        PortfolioItem(
            id: "1",
            providerId: "p1",
            beforePhotoUrl: nil,
            afterPhotoUrl: nil,
            description: "經典法式美甲",
            styleTags: ["法式", "經典", "簡約"],
            createdAt: Date()
        )
    ])
    .padding()
}
