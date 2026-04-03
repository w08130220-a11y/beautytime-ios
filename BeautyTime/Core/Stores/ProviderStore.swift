import Foundation

@Observable
class ProviderStore {
    // Search
    var providers: [Provider] = []
    var searchQuery = ""
    var selectedCategory: ServiceCategory?
    var selectedCity: TaiwanCity?
    var selectedStyle: String?
    var currentPage = 1
    var hasMore = true

    // Detail
    var selectedProvider: Provider?
    var providerServices: [Service] = []
    var providerStaff: [StaffMember] = []
    var providerReviews: [Review] = []
    var providerPortfolio: [PortfolioItem] = []
    var providerHours: [BusinessHour] = []

    // Favorites
    var favorites: [Favorite] = []
    var favoriteProviderIds: Set<String> = []

    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Search

    func searchProviders(reset: Bool = false) async {
        if reset {
            currentPage = 1
            providers = []
            hasMore = true
        }
        guard hasMore else { return }
        isLoading = true
        do {
            var queryItems = [
                URLQueryItem(name: "page", value: "\(currentPage)"),
                URLQueryItem(name: "limit", value: "20")
            ]
            if let category = selectedCategory {
                queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
            }
            if let city = selectedCity {
                queryItems.append(URLQueryItem(name: "city", value: city.rawValue))
            }
            if !searchQuery.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: searchQuery))
            }
            if let style = selectedStyle {
                queryItems.append(URLQueryItem(name: "style", value: style))
            }

            // API returns { providers: [...], total: N }
            let response: ProvidersResponse = try await api.get(
                path: APIEndpoints.Providers.list,
                queryItems: queryItems
            )
            providers.append(contentsOf: response.providers)
            hasMore = response.providers.count >= 20
            currentPage += 1
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        await searchProviders()
    }

    // MARK: - Provider Detail

    func loadProviderDetail(id: String) async {
        isLoading = true
        do {
            // API returns { provider: {...}, services: [...], staff: [...], ... } in one call
            let response: ProviderDetailResponse = try await api.get(
                path: APIEndpoints.Providers.detail(id)
            )
            selectedProvider = response.provider
            providerServices = response.services ?? []
            providerStaff = response.staff ?? []
            providerReviews = response.reviews ?? []
            providerPortfolio = response.portfolio ?? []
            providerHours = response.allHours
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Favorites

    func loadFavorites() async {
        do {
            var rawFavorites: [Favorite]
            do {
                rawFavorites = try await api.get(path: APIEndpoints.Users.myFavorites)
            } catch {
                rawFavorites = try await api.get(path: APIEndpoints.Favorites.list)
            }

            favoriteProviderIds = Set(rawFavorites.compactMap { $0.providerId })

            // If favorites don't include provider details, fetch them concurrently
            if rawFavorites.first?.provider == nil, !rawFavorites.isEmpty {
                var enriched = rawFavorites
                await withTaskGroup(of: (Int, Provider?).self) { group in
                    for (index, fav) in rawFavorites.enumerated() {
                        guard let pid = fav.providerId else { continue }
                        group.addTask { [api] in
                            let detail: ProviderDetailResponse? = try? await api.get(
                                path: APIEndpoints.Providers.detail(pid)
                            )
                            return (index, detail?.provider)
                        }
                    }
                    for await (index, provider) in group {
                        if let provider {
                            let fav = enriched[index]
                            enriched[index] = Favorite(
                                id: fav.id, userId: fav.userId, providerId: fav.providerId,
                                provider: provider, createdAt: fav.createdAt
                            )
                        }
                    }
                }
                favorites = enriched
            } else {
                favorites = rawFavorites
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleFavorite(providerId: String) async {
        // Optimistic UI update
        let wasFavorite = favoriteProviderIds.contains(providerId)
        if wasFavorite {
            favoriteProviderIds.remove(providerId)
            favorites.removeAll { $0.providerId == providerId }
        } else {
            favoriteProviderIds.insert(providerId)
        }

        do {
            let response: FavoriteToggleResponse = try await api.post(
                path: APIEndpoints.Favorites.toggle,
                body: ["providerId": providerId]
            )
            // Sync with server response
            if response.favorited {
                favoriteProviderIds.insert(providerId)
            } else {
                favoriteProviderIds.remove(providerId)
                favorites.removeAll { $0.providerId == providerId }
            }
        } catch {
            // Revert on failure
            if wasFavorite {
                favoriteProviderIds.insert(providerId)
            } else {
                favoriteProviderIds.remove(providerId)
            }
            self.error = error.localizedDescription
        }
    }

    func checkFavorite(providerId: String) async {
        do {
            let response: FavoriteCheckResponse = try await api.get(
                path: APIEndpoints.Favorites.check(providerId)
            )
            if response.favorited {
                favoriteProviderIds.insert(providerId)
            } else {
                favoriteProviderIds.remove(providerId)
            }
        } catch {
            // silently handle
        }
    }

    func isFavorite(_ providerId: String) -> Bool {
        favoriteProviderIds.contains(providerId)
    }
}
