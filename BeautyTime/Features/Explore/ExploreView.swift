import SwiftUI
import Kingfisher

struct ExploreView: View {
    @Environment(ProviderStore.self) private var store
    @State private var showFilter = false
    @State private var announcements: [Announcement] = []
    @State private var popularTags: [PopularTag] = []
    @State private var selectedTags: Set<String> = []

    private let columns = [
        GridItem(.flexible(), spacing: BTSpacing.lg),
        GridItem(.flexible(), spacing: BTSpacing.lg)
    ]

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Announcements banner
                if !announcements.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BTSpacing.md) {
                            ForEach(announcements) { announcement in
                                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                                    Text(announcement.title ?? "公告")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(BTColor.textPrimary)
                                        .lineLimit(1)
                                    if let content = announcement.content {
                                        Text(content)
                                            .font(.caption)
                                            .foregroundStyle(BTColor.textSecondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(BTSpacing.md)
                                .frame(width: 260, alignment: .leading)
                                .background(BTColor.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: BTRadius.md)
                                        .stroke(BTColor.primary.opacity(0.15), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, BTSpacing.lg)
                    }
                }

                // Search bar + filter button
                HStack(spacing: BTSpacing.sm) {
                    SearchBar(text: $store.searchQuery, placeholder: "搜尋美容師、店家...") {
                        Task { await store.searchProviders(reset: true) }
                        // Record search history (fire-and-forget)
                        if !store.searchQuery.isEmpty {
                            Task {
                                var body: [String: Any] = ["query": store.searchQuery]
                                var filters: [String: String] = [:]
                                if let cat = store.selectedCategory { filters["category"] = cat.rawValue }
                                if let city = store.selectedCity { filters["city"] = city.displayName }
                                if !filters.isEmpty { body["filters"] = filters }
                                let _: [String: String]? = try? await APIClient.shared.post(
                                    path: APIEndpoints.Survey.searchHistory,
                                    body: JSONBody(body)
                                )
                            }
                        }
                    }
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundStyle(BTColor.primary)
                            .frame(width: 44, height: 44)
                            .background(BTColor.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: BTRadius.md)
                                    .stroke(BTColor.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, BTSpacing.lg)

                // Category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BTSpacing.sm) {
                        CategoryChip(
                            title: "全部",
                            icon: "sparkles",
                            isSelected: store.selectedCategory == nil
                        ) {
                            store.selectedCategory = nil
                            Task { await store.searchProviders(reset: true) }
                        }
                        ForEach(ServiceCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.displayName,
                                icon: category.iconName,
                                isSelected: store.selectedCategory == category
                            ) {
                                store.selectedCategory = category
                                Task { await store.searchProviders(reset: true) }
                            }
                        }
                    }
                    .padding(.horizontal, BTSpacing.lg)
                }

                // Style tags row
                if !popularTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BTSpacing.sm) {
                            ForEach(popularTags, id: \.tag) { tagItem in
                                StyleTagChip(
                                    tag: tagItem.tag,
                                    count: tagItem.count,
                                    isSelected: selectedTags.contains(tagItem.tag)
                                ) {
                                    if selectedTags.contains(tagItem.tag) {
                                        selectedTags.remove(tagItem.tag)
                                    } else {
                                        selectedTags.insert(tagItem.tag)
                                    }
                                    store.selectedStyle = selectedTags.first
                                    Task { await store.searchProviders(reset: true) }
                                }
                            }
                        }
                        .padding(.horizontal, BTSpacing.lg)
                    }
                }

                // Provider grid
                LazyVGrid(columns: columns, spacing: BTSpacing.lg) {
                    ForEach(store.providers) { provider in
                        ProviderCard(provider: provider)
                            .onAppear {
                                if provider.id == store.providers.last?.id {
                                    Task { await store.loadMore() }
                                }
                            }
                    }
                }
                .padding(.horizontal, BTSpacing.lg)

                if store.isLoading {
                    ProgressView()
                        .tint(BTColor.primary)
                        .padding(BTSpacing.xl)
                }

                if store.providers.isEmpty && !store.isLoading {
                    ContentUnavailableView(
                        "找不到結果",
                        systemImage: "magnifyingglass",
                        description: Text("試試其他搜尋條件")
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.vertical, BTSpacing.lg)
        }
        .background(BTColor.background)
        .refreshable {
            async let a: () = store.searchProviders(reset: true)
            async let b: () = loadAnnouncements()
            async let c: () = loadPopularTags()
            _ = await (a, b, c)
        }
        .task {
            async let a: () = loadAnnouncements()
            async let b: () = loadPopularTags()
            _ = await (a, b)
        }
        .navigationTitle("探索")
        .sheet(isPresented: $showFilter) {
            FilterSheet(
                selectedCategory: $store.selectedCategory,
                selectedCity: $store.selectedCity,
                selectedTags: $selectedTags
            ) {
                Task { await store.searchProviders(reset: true) }
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            if store.providers.isEmpty {
                await store.searchProviders(reset: true)
            }
        }
    }
}

// MARK: - Data Loading

extension ExploreView {
    func loadAnnouncements() async {
        do {
            announcements = try await APIClient.shared.get(path: APIEndpoints.Announcements.published)
        } catch {
            // Silently fail - announcements are not critical
        }
    }

    func loadPopularTags() async {
        do {
            popularTags = try await APIClient.shared.get(path: APIEndpoints.Providers.popularTags)
        } catch {
            // Silently fail - tags are not critical
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BTSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, BTSpacing.sm)
            .background(isSelected ? BTColor.primary : BTColor.secondaryBackground)
            .foregroundStyle(isSelected ? .white : BTColor.textPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Style Tag Chip

private struct StyleTagChip: View {
    let tag: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("#\(tag)")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, BTSpacing.md)
                .padding(.vertical, BTSpacing.sm)
                .background(isSelected ? BTColor.primary.opacity(0.15) : BTColor.cardBackground)
                .foregroundStyle(isSelected ? BTColor.primary : BTColor.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? BTColor.primary.opacity(0.3) : BTColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ExploreView()
            .environment(ProviderStore())
    }
}
