import SwiftUI

struct MyBookingsView: View {
    @State private var bookings: [Booking] = []
    @State private var selectedStatus: BookingStatus?
    @State private var isLoading = false
    @State private var error: String?

    private let api = APIClient.shared

    var filteredBookings: [Booking] {
        guard let status = selectedStatus else { return bookings }
        return bookings.filter { $0.status == status }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusFilter
                bookingList
            }
            .navigationTitle("我的預約")
            .task { await loadBookings() }
            .refreshable { await loadBookings() }
        }
    }

    private var statusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "全部", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(BookingStatus.allCases, id: \.self) { status in
                    FilterChip(title: status.displayName, isSelected: selectedStatus == status) {
                        selectedStatus = status
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var bookingList: some View {
        if isLoading && bookings.isEmpty {
            LoadingView()
        } else if filteredBookings.isEmpty {
            EmptyStateView(
                icon: "calendar.badge.exclamationmark",
                title: "沒有預約",
                message: "你還沒有任何預約記錄"
            )
        } else {
            List(filteredBookings) { booking in
                NavigationLink {
                    BookingDetailView(booking: booking)
                } label: {
                    BookingRow(booking: booking)
                }
            }
            .listStyle(.plain)
        }
    }

    private func loadBookings() async {
        isLoading = true
        do {
            bookings = try await api.get(path: APIEndpoints.Bookings.my)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(booking.service?.name ?? "服務")
                    .font(.headline)
                Spacer()
                if let status = booking.status {
                    Text(status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.color.opacity(0.15))
                        .foregroundStyle(status.color)
                        .clipShape(Capsule())
                }
            }

            HStack {
                if let providerName = booking.provider?.name {
                    Label(providerName, systemImage: "storefront")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let staffName = booking.staff?.name {
                    Label(staffName, systemImage: "person")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                if let date = booking.date, let time = booking.time {
                    Label("\(Formatters.formatDate(date)) \(time)", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let price = booking.totalPrice {
                    Text(Formatters.formatPrice(price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

extension BookingStatus: CaseIterable {
    static var allCases: [BookingStatus] {
        [.pending, .confirmed, .completed, .cancelled, .disputed]
    }
}
