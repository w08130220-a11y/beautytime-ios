import SwiftUI

/// A summary card showing today's key metrics at a glance.
/// Shows: today's booking count, next booking time, and this week's revenue.
/// Designed to be the first thing the merchant sees when opening the app.
struct TodayDashboardCard: View {
    let stats: DashboardStats?
    let nextBooking: Booking?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今日總覽")
                        .font(.headline)
                    Text(Formatters.displayDate(Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Metrics row
            HStack(spacing: 0) {
                metricItem(
                    value: "\(stats?.todayBookings ?? 0)",
                    label: "今日預約",
                    icon: "calendar.badge.clock"
                )
                Divider().frame(height: 40)
                metricItem(
                    value: "\(stats?.pendingBookings ?? 0)",
                    label: "待確認",
                    icon: "exclamationmark.circle"
                )
                Divider().frame(height: 40)
                metricItem(
                    value: Formatters.formatPrice(stats?.todayRevenue ?? 0),
                    label: "今日營收",
                    icon: "dollarsign.circle"
                )
            }

            // Next booking
            if let next = nextBooking {
                Divider()
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("下一個預約")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(next.time ?? "--:--")  \(next.service?.name ?? "服務")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    if let staffName = next.staff?.name {
                        Text(staffName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("今天沒有更多預約了")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func metricItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TodayDashboardCard(
        stats: DashboardStats(
            todayBookings: 3,
            todayRevenue: 4500,
            pendingBookings: 1,
            totalCustomers: 42,
            monthlyRevenue: 85000,
            monthlyBookings: 28
        ),
        nextBooking: nil
    )
    .padding()
}
