import SwiftUI
import Kingfisher

struct MatchDetailView: View {
    let requestId: String

    @State private var request: MatchRequest?
    @State private var isLoading = false
    @State private var error: String?
    @State private var isClosing = false
    @State private var showCloseConfirmation = false
    @State private var acceptedOfferId: String?

    private let api = APIClient.shared

    var body: some View {
        content
            .navigationTitle("需求詳情")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadDetail() }
            .refreshable { await loadDetail() }
            .confirmationDialog(
                "確定要關閉此需求嗎？",
                isPresented: $showCloseConfirmation,
                titleVisibility: .visible
            ) {
                Button("關閉需求", role: .destructive) {
                    Task { await closeRequest() }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && request == nil {
            LoadingView()
        } else if let error, request == nil {
            ErrorView(message: error) {
                Task { await loadDetail() }
            }
        } else if let request {
            ScrollView {
                VStack(spacing: 20) {
                    requestInfoCard(request)
                    offersSection(request)
                }
                .padding()
            }
        }
    }

    // MARK: - Request Info Card

    private func requestInfoCard(_ request: MatchRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let serviceType = request.serviceType,
                   let category = ServiceCategory(rawValue: serviceType) {
                    Label(category.displayName, systemImage: category.iconName)
                        .font(.title3.bold())
                } else {
                    Text(request.serviceType ?? "服務")
                        .font(.title3.bold())
                }
                Spacer()
                if let status = request.status {
                    StatusBadge(text: status.displayName, color: status.color)
                }
            }

            Divider()

            if let date = request.preferredDate {
                Label(Formatters.formatDate(date), systemImage: "calendar")
                    .font(.subheadline)
            }

            if let time = request.preferredTime {
                Label(time, systemImage: "clock")
                    .font(.subheadline)
            }

            if let cityRaw = request.locationCity,
               let city = TaiwanCity(rawValue: cityRaw) {
                let location = [city.displayName, request.locationDistrict]
                    .compactMap { $0 }
                    .joined(separator: " ")
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
            }

            if let min = request.budgetMin, let max = request.budgetMax {
                Label(
                    "\(Formatters.formatPrice(min)) – \(Formatters.formatPrice(max))",
                    systemImage: "dollarsign.circle"
                )
                .font(.subheadline)
            } else if let min = request.budgetMin {
                Label("\(Formatters.formatPrice(min)) 起", systemImage: "dollarsign.circle")
                    .font(.subheadline)
            } else if let max = request.budgetMax {
                Label("最多 \(Formatters.formatPrice(max))", systemImage: "dollarsign.circle")
                    .font(.subheadline)
            }

            if let note = request.note, !note.isEmpty {
                Label(note, systemImage: "note.text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if request.status == .open {
                Button(role: .destructive) {
                    showCloseConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        if isClosing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("關閉需求")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(isClosing)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // MARK: - Offers Section

    @ViewBuilder
    private func offersSection(_ request: MatchRequest) -> some View {
        let offers = request.offers ?? []

        VStack(alignment: .leading, spacing: 12) {
            Text("報價 (\(offers.count))")
                .font(.headline)

            if offers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("尚無報價")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(offers) { offer in
                    offerCard(offer, requestStatus: request.status)
                }
            }
        }
    }

    // MARK: - Offer Card

    private func offerCard(_ offer: MatchOffer, requestStatus: MatchStatus?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Provider info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.provider?.name ?? "美容師")
                        .font(.headline)
                    HStack(spacing: 12) {
                        if let rating = offer.provider?.rating {
                            Label(String(format: "%.1f", rating), systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        if let category = offer.provider?.category {
                            Text(category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                offerStatusBadge(offer.status)
            }

            Divider()

            // Quoted price
            if let price = offer.quotedPrice {
                Label(Formatters.formatPrice(price), systemImage: "tag.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accentColor)
            }

            // Available time slots
            if let slots = offer.availableSlots, !slots.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("可預約時段")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(slots, id: \.self) { slot in
                            Text(slot)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Message
            if let message = offer.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Portfolio images
            if let urls = offer.portfolioUrls, !urls.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("作品集")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(urls, id: \.self) { urlString in
                                if let url = URL(string: urlString) {
                                    KFImage(url)
                                        .placeholder {
                                            Color(.systemGray5)
                                        }
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }

            // Action buttons
            if offer.status == .pending && requestStatus == .open {
                HStack(spacing: 12) {
                    Button {
                        Task { await rejectOffer(offer.id) }
                    } label: {
                        Text("拒絕")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task { await acceptOffer(offer.id) }
                    } label: {
                        Text("接受報價")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            }

            // Navigate to booking if accepted
            if offer.status == .accepted, let providerId = offer.providerId {
                NavigationLink {
                    BookingFlowView(providerId: providerId)
                } label: {
                    HStack {
                        Spacer()
                        Label("前往預約", systemImage: "calendar.badge.plus")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    // MARK: - Offer Status Badge

    @ViewBuilder
    private func offerStatusBadge(_ status: MatchOfferStatus?) -> some View {
        if let status {
            let (text, color): (String, Color) = {
                switch status {
                case .pending: return ("待回覆", .orange)
                case .accepted: return ("已接受", .green)
                case .rejected: return ("已拒絕", .gray)
                }
            }()
            StatusBadge(text: text, color: color)
        }
    }

    // MARK: - API Calls

    private func loadDetail() async {
        isLoading = true
        error = nil
        do {
            request = try await api.get(path: APIEndpoints.Match.requestDetail(requestId))
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func closeRequest() async {
        isClosing = true
        do {
            request = try await api.post(path: APIEndpoints.Match.closeRequest(requestId))
        } catch {
            self.error = error.localizedDescription
        }
        isClosing = false
    }

    private func acceptOffer(_ offerId: String) async {
        do {
            let _: MatchOffer = try await api.post(path: APIEndpoints.Match.acceptOffer(offerId))
            await loadDetail()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func rejectOffer(_ offerId: String) async {
        do {
            let _: MatchOffer = try await api.post(path: APIEndpoints.Match.rejectOffer(offerId))
            await loadDetail()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - FlowLayout (simple horizontal wrapping)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(requestId: "preview-id")
    }
}
