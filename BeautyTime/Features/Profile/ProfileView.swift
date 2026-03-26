import SwiftUI
import Kingfisher

struct ProfileView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(ProviderStore.self) private var providerStore
    @State private var showSignOutAlert = false
    @State private var unpaidCount = 0
    @State private var totalBookings = 0
    @State private var reviewCount = 0

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BTSpacing.lg) {
                    // MARK: - User Card
                    userCard

                    // MARK: - Pending Payment Banner
                    if unpaidCount > 0 {
                        pendingPaymentBanner
                    }

                    // MARK: - Stats Row
                    statsRow

                    // MARK: - Menu Section 1
                    menuSection1

                    // MARK: - Provider Registration
                    if authStore.currentUser?.role == .customer {
                        providerRegistrationCard
                    }

                    // MARK: - Menu Section 2
                    menuSection2

                    // MARK: - Menu Section 3
                    menuSection3

                    // MARK: - Sign Out
                    signOutButton

                    Spacer(minLength: BTSpacing.xxl)
                }
                .padding(.horizontal, BTSpacing.lg)
                .padding(.top, BTSpacing.md)
            }
            .background(BTColor.background)
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .task(id: "profile") {
                async let stats: () = loadStats()
                async let favs: () = providerStore.loadFavorites()
                _ = await (stats, favs)
            }
            .refreshable {
                async let stats: () = loadStats()
                async let favs: () = providerStore.loadFavorites()
                _ = await (stats, favs)
            }
            .alert("確定登出？", isPresented: $showSignOutAlert) {
                Button("登出", role: .destructive) {
                    authStore.signOut()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - User Card

    private var userCard: some View {
        HStack(spacing: BTSpacing.lg) {
            // Avatar
            if let avatarUrl = authStore.currentUser?.avatarUrl,
               let url = URL(string: avatarUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(BTColor.primary.opacity(0.2), lineWidth: 2))
            } else {
                Circle()
                    .fill(BTColor.secondaryBackground)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(BTColor.primary)
                    }
                    .overlay(Circle().stroke(BTColor.primary.opacity(0.2), lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(authStore.currentUser?.fullName ?? "未設定姓名")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BTColor.textPrimary)
                Text(authStore.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(BTColor.textSecondary)
            }

            Spacer()
        }
        .padding(BTSpacing.lg)
        .btCard()
    }

    // MARK: - Pending Payment Banner

    private var pendingPaymentBanner: some View {
        NavigationLink {
            UnpaidOrdersView()
        } label: {
            HStack {
                Image(systemName: "creditcard.trianglebadge.exclamationmark")
                    .font(.body)
                    .foregroundStyle(.white)

                Text("待付款")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)

                Text("\(unpaidCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BTColor.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.white)
                    .clipShape(Capsule())

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(BTSpacing.lg)
            .background(
                LinearGradient(
                    colors: [BTColor.primary, BTColor.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: BTSpacing.sm) {
            BTStatCard(value: "\(totalBookings)", label: "總預約數")
            BTStatCard(value: "\(reviewCount)", label: "已評價數")
            BTStatCard(value: "\(providerStore.favorites.count)", label: "收藏數")
        }
    }

    // MARK: - Menu Section 1 (Personal)

    private var menuSection1: some View {
        VStack(spacing: 0) {
            NavigationLink { EditProfileView() } label: {
                BTMenuRow(icon: "person.text.rectangle", title: "編輯個人資料")
            }
            Divider().padding(.leading, 36)

            NavigationLink { FavoritesView() } label: {
                BTMenuRow(icon: "heart", title: "收藏")
            }
            Divider().padding(.leading, 36)

            NavigationLink { MyCouponsView() } label: {
                BTMenuRow(icon: "tag", title: "優惠券")
            }
            Divider().padding(.leading, 36)

            NavigationLink { MyVouchersView() } label: {
                BTMenuRow(icon: "ticket", title: "我的票券")
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .btCard()
    }

    // MARK: - Provider Registration

    private var providerRegistrationCard: some View {
        NavigationLink {
            ProviderRegisterView()
        } label: {
            HStack(spacing: BTSpacing.md) {
                Image(systemName: "storefront.fill")
                    .font(.title2)
                    .foregroundStyle(BTColor.primary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("申請成為服務商")
                        .font(.headline)
                        .foregroundStyle(BTColor.textPrimary)
                    Text("開始在 BeautyTime 上提供服務")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
            }
            .padding(BTSpacing.lg)
        }
        .btCard()
    }

    // MARK: - Menu Section 2 (Settings)

    private var menuSection2: some View {
        VStack(spacing: 0) {
            NavigationLink { NotificationsView() } label: {
                BTMenuRow(icon: "bell", title: "通知設定")
            }
            Divider().padding(.leading, 36)

            NavigationLink { InvitationsView() } label: {
                BTMenuRow(icon: "envelope.open", title: "帳號綁定邀請")
            }
            Divider().padding(.leading, 36)

            NavigationLink { PaymentMethodsView() } label: {
                BTMenuRow(icon: "creditcard", title: "付款方式")
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .btCard()
    }

    // MARK: - Menu Section 3 (Support)

    private var menuSection3: some View {
        VStack(spacing: 0) {
            NavigationLink { PrivacyPolicyView() } label: {
                BTMenuRow(icon: "lock.shield", title: "隱私政策")
            }
            Divider().padding(.leading, 36)

            NavigationLink { HelpCenterView() } label: {
                BTMenuRow(icon: "questionmark.circle", title: "幫助中心")
            }
            Divider().padding(.leading, 36)

            NavigationLink { FeedbackView() } label: {
                BTMenuRow(icon: "bubble.left.and.text.bubble.right", title: "意見回饋")
            }
            Divider().padding(.leading, 36)

            NavigationLink { LanguageSettingsView() } label: {
                BTMenuRow(icon: "globe", title: "語言設定")
            }
            Divider().padding(.leading, 36)

            NavigationLink { AboutView() } label: {
                BTMenuRow(icon: "info.circle", title: "關於")
            }
        }
        .padding(.horizontal, BTSpacing.lg)
        .btCard()
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            showSignOutAlert = true
        } label: {
            Text("登出")
                .font(.body.weight(.medium))
                .foregroundStyle(BTColor.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BTSpacing.lg)
        }
        .btCard()
    }

    // MARK: - Load Stats

    private func loadStats() async {
        // Load bookings to count total and unpaid
        do {
            let bookings: [Booking] = try await api.get(path: APIEndpoints.Bookings.my)
            totalBookings = bookings.count
            unpaidCount = bookings.filter { $0.depositPaid != true && $0.status == .pending }.count
        } catch {
            #if DEBUG
            print("[Profile] Failed to load bookings: \(error)")
            #endif
        }

        // Load reviews count
        do {
            let reviews: [Review] = try await api.get(
                path: APIEndpoints.Reviews.list,
                queryItems: [URLQueryItem(name: "role", value: "customer")]
            )
            reviewCount = reviews.count
        } catch {
            #if DEBUG
            print("[Profile] Failed to load reviews: \(error)")
            #endif
        }
    }
}

// MARK: - Language Settings

private struct LanguageSettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var selectedLocale: AppLocale = .zhTW
    @State private var isSaving = false

    private let api = APIClient.shared

    var body: some View {
        List {
            Section(header: Text("選擇語言")) {
                ForEach([AppLocale.zhTW, .en], id: \.self) { locale in
                    HStack {
                        Text(locale == .zhTW ? "繁體中文" : "English")
                        Spacer()
                        if selectedLocale == locale {
                            Image(systemName: "checkmark")
                                .foregroundStyle(BTColor.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLocale = locale
                    }
                }
            }
        }
        .navigationTitle("語言設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedLocale = authStore.currentUser?.preferredLocale ?? .zhTW
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    Task { await saveLocale() }
                }
                .disabled(isSaving)
            }
        }
    }

    private func saveLocale() async {
        isSaving = true
        do {
            let _: User = try await api.patch(
                path: APIEndpoints.Auth.me,
                body: JSONBody(["preferredLocale": selectedLocale.rawValue])
            )
            await authStore.fetchCurrentUser()
        } catch {
            // silently handle
        }
        isSaving = false
    }
}

// MARK: - About

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Link(destination: URL(string: "https://www.btbeautytime.com/terms")!) {
                    Label("服務條款", systemImage: "doc.text")
                }
                Link(destination: URL(string: "https://www.btbeautytime.com/privacy")!) {
                    Label("隱私權政策", systemImage: "lock.shield")
                }
            }
        }
        .navigationTitle("關於")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.lg) {
                Group {
                    sectionBlock(title: "資料蒐集", content: "我們僅蒐集您使用服務所必要的個人資料，包括姓名、電子郵件、電話號碼及預約紀錄。")
                    sectionBlock(title: "資料使用", content: "您的資料僅用於提供預約服務、付款處理、客戶支援及服務改善。我們不會將您的資料出售給第三方。")
                    sectionBlock(title: "資料保護", content: "我們採用業界標準的加密技術保護您的個人資料。所有付款資訊由綠界科技(ECPay)安全處理。")
                    sectionBlock(title: "Cookie 政策", content: "我們使用 Cookie 來改善您的使用體驗。您可以在瀏覽器設定中管理 Cookie 偏好。")
                    sectionBlock(title: "您的權利", content: "您可以隨時要求查閱、修正或刪除您的個人資料。如需行使相關權利，請透過意見回饋功能與我們聯繫。")
                }

                // Link to full policy
                Link(destination: URL(string: "https://www.btbeautytime.com/privacy")!) {
                    HStack {
                        Text("查看完整隱私政策")
                            .font(.body.weight(.medium))
                        Image(systemName: "arrow.up.right.square")
                    }
                    .foregroundStyle(BTColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BTSpacing.lg)
                }
            }
            .padding(BTSpacing.lg)
        }
        .background(BTColor.background)
        .navigationTitle("隱私政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionBlock(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text(title)
                .font(.headline)
                .foregroundStyle(BTColor.textPrimary)
            Text(content)
                .font(.body)
                .foregroundStyle(BTColor.textSecondary)
                .lineSpacing(4)
        }
        .padding(BTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .btCard()
    }
}

// MARK: - Help Center

struct HelpCenterView: View {
    @State private var expandedId: String?

    private let faqs: [(id: String, question: String, answer: String)] = [
        ("1", "如何預約服務？", "在首頁瀏覽服務商，選擇您喜歡的服務後，選擇日期和時間即可完成預約。"),
        ("2", "如何取消預約？", "進入「我的預約」頁面，點選要取消的預約，再點擊「取消預約」按鈕。請注意，部分預約可能會收取取消費用。"),
        ("3", "付款方式有哪些？", "我們支援信用卡、ATM 轉帳、超商代碼繳費、Apple Pay 及 LINE Pay 等多種付款方式，所有付款均透過綠界科技安全處理。"),
        ("4", "如何使用票券？", "在預約時選擇「使用票券」，系統會自動扣抵您的票券餘額或次數。"),
        ("5", "如何使用優惠券？", "在付款頁面輸入優惠券代碼，系統會自動計算折扣金額。"),
        ("6", "如何成為服務商？", "進入個人頁面，點選「申請成為服務商」，填寫相關資料後送出申請，審核通過即可開始提供服務。"),
        ("7", "如何修改個人資料？", "進入個人頁面，點選「編輯個人資料」即可修改您的姓名、頭像等資訊。"),
        ("8", "遇到問題如何聯繫客服？", "您可以透過「意見回饋」功能向我們反映問題，我們會盡快回覆您。"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.sm) {
                ForEach(faqs, id: \.id) { faq in
                    faqRow(faq: faq)
                }
            }
            .padding(BTSpacing.lg)
        }
        .background(BTColor.background)
        .navigationTitle("幫助中心")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func faqRow(faq: (id: String, question: String, answer: String)) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedId = expandedId == faq.id ? nil : faq.id
                }
            } label: {
                HStack {
                    Text(faq.question)
                        .font(.body.weight(.medium))
                        .foregroundStyle(BTColor.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expandedId == faq.id ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(BTColor.textTertiary)
                }
                .padding(BTSpacing.lg)
            }

            if expandedId == faq.id {
                Text(faq.answer)
                    .font(.body)
                    .foregroundStyle(BTColor.textSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, BTSpacing.lg)
                    .padding(.bottom, BTSpacing.lg)
            }
        }
        .btCard()
    }
}

// MARK: - Feedback

struct FeedbackView: View {
    @State private var feedbackText = ""
    @State private var feedbackType = "suggestion"
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    private let feedbackTypes = [
        ("suggestion", "建議"),
        ("bug", "問題回報"),
        ("complaint", "投訴"),
        ("other", "其他"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                // Feedback Type Picker
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    Text("回饋類型")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BTColor.textSecondary)

                    HStack(spacing: BTSpacing.sm) {
                        ForEach(feedbackTypes, id: \.0) { type in
                            Button {
                                feedbackType = type.0
                            } label: {
                                Text(type.1)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(feedbackType == type.0 ? .white : BTColor.textPrimary)
                                    .padding(.horizontal, BTSpacing.md)
                                    .padding(.vertical, BTSpacing.sm)
                                    .background(feedbackType == type.0 ? BTColor.primary : BTColor.cardBackground)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(
                                            feedbackType == type.0 ? Color.clear : BTColor.border,
                                            lineWidth: 1
                                        )
                                    )
                            }
                        }
                    }
                }

                // Text Area
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    Text("意見內容")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BTColor.textSecondary)

                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 200)
                        .padding(BTSpacing.md)
                        .background(BTColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.md)
                                .stroke(BTColor.border, lineWidth: 1)
                        )

                    Text("\(feedbackText.count)/500")
                        .font(.caption)
                        .foregroundStyle(BTColor.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Submit Button
                Button {
                    Task { await submitFeedback() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .btPrimaryButton()
                    } else {
                        Text("送出回饋")
                            .btPrimaryButton(isDisabled: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding(BTSpacing.lg)
        }
        .background(BTColor.background)
        .navigationTitle("意見回饋")
        .navigationBarTitleDisplayMode(.inline)
        .alert("感謝您的回饋！", isPresented: $showSuccess) {
            Button("確定") { dismiss() }
        } message: {
            Text("我們已收到您的意見，會盡快處理。")
        }
    }

    private func submitFeedback() async {
        isSubmitting = true
        // For now, just simulate a brief delay since no backend endpoint exists yet
        try? await Task.sleep(for: .seconds(1))
        isSubmitting = false
        showSuccess = true
    }
}

#Preview {
    ProfileView()
        .environment(AuthStore())
}
