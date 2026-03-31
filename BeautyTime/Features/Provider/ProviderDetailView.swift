import SwiftUI
import Kingfisher

struct ProviderDetailView: View {
    let providerId: String
    @Environment(ProviderStore.self) private var store
    @State private var selectedTab = DetailTab.services
    @State private var showBookingFlow = false
    @State private var showVoucherPurchase = false

    enum DetailTab: String, CaseIterable {
        case services = "服務項目"
        case staff = "設計師"
        case portfolio = "作品集"
        case plans = "方案"
        case reviews = "顧客評價"
        case hours = "營業時間"
    }

    private var provider: Provider? { store.selectedProvider }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero cover image
                    heroSection

                    // Provider info
                    providerInfoSection

                    // Scrollable tab bar
                    ScrollableTabBar(
                        tabs: DetailTab.allCases,
                        selection: $selectedTab
                    )
                    .padding(.top, BTSpacing.sm)

                    // Tab content
                    tabContent
                        .padding(.top, BTSpacing.md)
                }
                .padding(.bottom, 90) // Space for floating button
            }
            .refreshable {
                await store.loadProviderDetail(id: providerId)
            }

            // Floating booking button
            floatingBookButton
        }
        .background(BTColor.background)
        .navigationTitle(provider?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await store.toggleFavorite(providerId: providerId)
                    }
                } label: {
                    Image(systemName: store.isFavorite(providerId) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(providerId) ? .red : BTColor.textSecondary)
                }
            }
        }
        .navigationDestination(isPresented: $showBookingFlow) {
            BookingFlowView(providerId: providerId)
        }
        .sheet(isPresented: $showVoucherPurchase) {
            NavigationStack {
                VoucherPurchaseView(providerId: providerId)
            }
        }
        .task {
            await store.loadProviderDetail(id: providerId)
            await store.checkFavorite(providerId: providerId)
            // Record browse history (fire-and-forget)
            Task {
                let _: [String: String]? = try? await APIClient.shared.post(
                    path: APIEndpoints.Survey.browseHistory,
                    body: ["providerId": providerId]
                )
            }
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private var heroSection: some View {
        KFImage(URL(string: provider?.imageUrl ?? ""))
            .placeholder {
                Rectangle()
                    .fill(BTColor.secondaryBackground)
                    .overlay {
                        Image(systemName: provider?.category?.iconName ?? "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(BTColor.primaryLight)
                    }
            }
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 9, contentMode: .fill)
            .clipped()
    }

    // MARK: - Provider Info Section

    @ViewBuilder
    private var providerInfoSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Name + verified badge
            HStack(spacing: BTSpacing.sm) {
                Text(provider?.name ?? "")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(BTColor.textPrimary)

                if provider?.isVerified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(BTColor.primary)
                        .font(.title3)
                }

                Spacer()
            }

            // Category badge + rating
            HStack(spacing: BTSpacing.md) {
                if let category = provider?.category {
                    BTBadge(text: category.displayName, color: BTColor.primary)
                }

                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(BTColor.warning)
                    Text(String(format: "%.1f", provider?.rating ?? 0))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BTColor.textPrimary)
                    Text("(\(provider?.reviewCount ?? 0))")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }

                Spacer()
            }

            // Location — 點擊開啟 Google Maps
            if let address = provider?.address, !address.isEmpty {
                Button {
                    let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
                    // 優先開啟 Google Maps app，沒裝則用瀏覽器
                    let gmapsUrl = URL(string: "comgooglemaps://?q=\(encoded)")
                    let webUrl = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)")
                    if let gmapsUrl, UIApplication.shared.canOpenURL(gmapsUrl) {
                        UIApplication.shared.open(gmapsUrl)
                    } else if let webUrl {
                        UIApplication.shared.open(webUrl)
                    }
                } label: {
                    HStack(spacing: BTSpacing.sm) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(BTColor.primary)
                        Text(address)
                            .font(.subheadline)
                            .foregroundStyle(BTColor.info)
                    }
                }
                .buttonStyle(.plain)
            }

            // Phone — 點擊撥打電話
            if let phone = provider?.phone, !phone.isEmpty {
                Button {
                    let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
                    if let url = URL(string: "tel:\(cleaned)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: BTSpacing.sm) {
                        Image(systemName: "phone")
                            .font(.caption)
                            .foregroundStyle(BTColor.primary)
                        Text(phone)
                            .font(.subheadline)
                            .foregroundStyle(BTColor.info)
                    }
                }
                .buttonStyle(.plain)
            }

            // Instagram — 優先開啟 Instagram app
            if let instagram = provider?.instagramUrl, !instagram.isEmpty {
                Button {
                    // 從 URL 或使用者名稱中取得 username
                    let username = instagram
                        .replacingOccurrences(of: "https://www.instagram.com/", with: "")
                        .replacingOccurrences(of: "https://instagram.com/", with: "")
                        .replacingOccurrences(of: "http://www.instagram.com/", with: "")
                        .replacingOccurrences(of: "http://instagram.com/", with: "")
                        .trimmingCharacters(in: CharacterSet(charactersIn: "/@"))

                    let appUrl = URL(string: "instagram://user?username=\(username)")
                    let webUrl = URL(string: "https://www.instagram.com/\(username)/")

                    if let appUrl, UIApplication.shared.canOpenURL(appUrl) {
                        UIApplication.shared.open(appUrl)
                    } else if let webUrl {
                        UIApplication.shared.open(webUrl)
                    }
                } label: {
                    HStack(spacing: BTSpacing.sm) {
                        Image(systemName: "camera")
                            .font(.caption)
                            .foregroundStyle(BTColor.primary)
                        Text("查看 Instagram")
                            .font(.subheadline)
                            .foregroundStyle(BTColor.info)
                    }
                }
                .buttonStyle(.plain)
            }

            // Description
            if let desc = provider?.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(BTColor.textSecondary)
                    .lineLimit(3)
                    .padding(.top, BTSpacing.xs)
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .padding(.vertical, BTSpacing.lg)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .services:
            servicesSection
        case .staff:
            StaffTab(providerId: providerId)
        case .portfolio:
            PortfolioSection(items: store.providerPortfolio)
                .padding(.horizontal, BTSpacing.lg)
        case .plans:
            PlansTab(providerId: providerId)
        case .reviews:
            ReviewsSection(
                reviews: store.providerReviews,
                showAll: true
            )
            .padding(.horizontal, BTSpacing.lg)
        case .hours:
            BusinessHoursTab(hours: store.providerHours)
                .padding(.horizontal, BTSpacing.lg)
        }
    }

    // MARK: - Services Section

    @ViewBuilder
    private var servicesSection: some View {
        LazyVStack(spacing: BTSpacing.md) {
            ForEach(store.providerServices) { service in
                ServiceRow(service: service) {
                    showBookingFlow = true
                }
            }
        }
        .padding(.horizontal, BTSpacing.lg)

        if store.providerServices.isEmpty && !store.isLoading {
            emptyStateView(icon: "scissors", text: "尚無服務項目")
        }
    }

    // MARK: - Floating Book Button

    @ViewBuilder
    private var floatingBookButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showBookingFlow = true
            } label: {
                Text("立即預約")
                    .font(.headline)
                    .btPrimaryButton()
            }
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.sm)
        }
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func emptyStateView(icon: String, text: String) -> some View {
        VStack(spacing: BTSpacing.md) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(BTColor.textTertiary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(BTColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BTSpacing.xxl)
    }
}

// MARK: - Scrollable Tab Bar

private struct ScrollableTabBar: View {
    let tabs: [ProviderDetailView.DetailTab]
    @Binding var selection: ProviderDetailView.DetailTab
    @Namespace private var tabNamespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BTSpacing.xl) {
                    ForEach(tabs, id: \.self) { tab in
                        tabItem(tab)
                            .id(tab)
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
            }
            .onChange(of: selection) { _, newValue in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    @ViewBuilder
    private func tabItem(_ tab: ProviderDetailView.DetailTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selection = tab
            }
        } label: {
            VStack(spacing: BTSpacing.sm) {
                Text(tab.rawValue)
                    .font(.subheadline.weight(selection == tab ? .semibold : .regular))
                    .foregroundStyle(selection == tab ? BTColor.primary : BTColor.textSecondary)

                // Indicator
                if selection == tab {
                    Capsule()
                        .fill(BTColor.primary)
                        .frame(height: 3)
                        .matchedGeometryEffect(id: "tab_indicator", in: tabNamespace)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Service Row

private struct ServiceRow: View {
    let service: Service
    let onBook: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(service.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BTColor.textPrimary)
                HStack(spacing: BTSpacing.sm) {
                    if let duration = service.duration {
                        Label("\(duration) 分鐘", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(BTColor.textSecondary)
                    }
                    if let price = service.price {
                        Text(Formatters.formatPrice(price))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BTColor.primary)
                    }
                }
            }
            Spacer()
            Button("預約", action: onBook)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, BTSpacing.lg)
                .padding(.vertical, BTSpacing.sm)
                .background(BTColor.primary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .padding(BTSpacing.lg)
        .btCard()
    }
}

// MARK: - Business Hours Tab

struct BusinessHoursTab: View {
    let hours: [BusinessHour]

    var body: some View {
        if hours.isEmpty {
            VStack(spacing: BTSpacing.md) {
                Image(systemName: "clock")
                    .font(.largeTitle)
                    .foregroundStyle(BTColor.textTertiary)
                Text("尚無營業時間資訊")
                    .font(.subheadline)
                    .foregroundStyle(BTColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, BTSpacing.xxl)
        } else {
            VStack(spacing: 0) {
                ForEach(hours) { hour in
                    HStack {
                        Text(dayName(hour.dayOfWeek))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BTColor.textPrimary)
                            .frame(width: 50, alignment: .leading)

                        Spacer()

                        if hour.isOpen == true {
                            Text("\(hour.openTime ?? "") - \(hour.closeTime ?? "")")
                                .font(.subheadline)
                                .foregroundStyle(BTColor.textPrimary)
                        } else {
                            Text("公休")
                                .font(.subheadline)
                                .foregroundStyle(BTColor.textTertiary)
                        }
                    }
                    .padding(.vertical, BTSpacing.md)

                    if hour.id != hours.last?.id {
                        Divider()
                    }
                }
            }
            .padding(BTSpacing.lg)
            .btCard()
        }
    }

    private func dayName(_ day: Int) -> String {
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        guard day >= 0, day < names.count else { return "" }
        return "週\(names[day])"
    }
}


#Preview {
    NavigationStack {
        ProviderDetailView(providerId: "1")
            .environment(ProviderStore())
    }
}
