import SwiftUI
import Kingfisher

struct ScheduleView: View {
    @Environment(ManageStore.self) private var store

    @State private var selectedDate = Date()
    @State private var expandedBookingId: String?

    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    private var filteredBookings: [Booking] {
        store.todayBookings.filter { $0.date == selectedDateString }
    }

    var body: some View {
        VStack(spacing: 0) {
            calendarStrip
            Divider()
            bookingsList
        }
        .navigationTitle("排班表")
        .task {
            await store.loadDashboard()
        }
    }

    // MARK: - Calendar Strip

    private var calendarStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    DateCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Bookings List

    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredBookings.isEmpty {
                    ContentUnavailableView(
                        "無預約",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("這天沒有預約")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(filteredBookings) { booking in
                        ScheduleBookingCard(
                            booking: booking,
                            isExpanded: expandedBookingId == booking.id,
                            onToggle: {
                                withAnimation {
                                    expandedBookingId = expandedBookingId == booking.id ? nil : booking.id
                                }
                            },
                            onConfirm: {
                                Task { await store.confirmBooking(id: booking.id) }
                            },
                            onComplete: {
                                Task { await store.completeBooking(id: booking.id) }
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Date Cell

private struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-TW")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(.caption)
                .foregroundStyle(isSelected ? .white : .secondary)
            Text(dayNumber)
                .font(.headline)
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(width: 48, height: 64)
        .background(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.15) : Color(.systemGray6)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Schedule Booking Card

private struct ScheduleBookingCard: View {
    let booking: Booking
    let isExpanded: Bool
    let onToggle: () -> Void
    let onConfirm: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.time ?? "--:--")
                            .font(.headline)
                            .monospacedDigit()
                        if let duration = booking.duration {
                            Text("\(duration) 分鐘")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()
                        .frame(height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.service?.name ?? "未知服務")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(booking.customer?.fullName ?? "顧客")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(booking.staff?.name ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let status = booking.status {
                            Text(status.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(status.color.opacity(0.15))
                                .foregroundStyle(status.color)
                                .clipShape(Capsule())
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                HStack(spacing: 12) {
                    if booking.status == .pending {
                        Button(action: onConfirm) {
                            Label("確認", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }

                    if booking.status == .confirmed {
                        Button(action: onComplete) {
                            Label("完成", systemImage: "checkmark.seal.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ScheduleView()
            .environment(ManageStore())
    }
}
