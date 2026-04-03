import SwiftUI
import Kingfisher

struct FavoritesView: View {
    @Environment(ProviderStore.self) private var providerStore
    @State private var isLoading = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if isLoading && providerStore.favorites.isEmpty {
                LoadingView()
            } else if providerStore.favorites.isEmpty {
                EmptyStateView(
                    icon: "heart.slash",
                    title: "沒有收藏",
                    message: "你還沒有收藏任何店家"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(providerStore.favorites) { favorite in
                            if let provider = favorite.provider {
                                FavoriteProviderRow(
                                    provider: provider,
                                    onUnfavorite: {
                                        Task {
                                            await providerStore.toggleFavorite(providerId: provider.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("我的收藏")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadFavorites() }
        .refreshable { await loadFavorites() }
    }

    private func loadFavorites() async {
        isLoading = true
        await providerStore.loadFavorites()
        isLoading = false
    }
}

// MARK: - Favorite Provider Row

private struct FavoriteProviderRow: View {
    let provider: Provider
    let onUnfavorite: () -> Void

    var body: some View {
        NavigationLink {
            ProviderDetailView(providerId: provider.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    KFImage(URL(string: provider.imageUrl ?? ""))
                        .placeholder {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay {
                                    Image(systemName: provider.category?.iconName ?? "sparkles")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button {
                        onUnfavorite()
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(6)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let category = provider.category {
                        Text(category.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let city = provider.city {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin")
                                .font(.system(size: 9))
                            Text(city + (provider.district.map { " \($0)" } ?? ""))
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
            .environment(ProviderStore())
    }
}
