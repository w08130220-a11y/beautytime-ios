import SwiftUI
import Kingfisher

struct DashboardView: View {
    @Environment(DashboardStore.self) private var store
    @State private var showAddService = false
    @State private var showSchedule = false
    @State private var showOrders = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                welcomeHeader
                todayStats
                monthlyStats
                quickActions
                upcomingBookings
            }
            .padding(BTSpacing.lg)
        }
        .btPageBackground()
        .navigationTitle("管理面板")
        .navigationDestination(isPresented: $showAddService) {
            ServicesManageView()
        }
        .navigationDestination(isPresented: $showSchedule) {
            ScheduleView()
        }
        .navigationDestination(isPresented: $showOrders) {
            OrdersManageView()
        }
        .task {
            await store.loadDashboardStats()
        }
        .refreshable {
            await store.loadDashboardStats()
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            Text("歡迎回來")
                .font(.subheadline)
                .foregroundStyle(BTColor.textSecondary)
            Text("管理您的店鋪")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(BTColor.textPrimary)
        }
    }

    // MARK: - Today Stats

    private var todayStats: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("今日概況")
                .font(.headline)
                .foregroundStyle(BTColor.textPrimary)

            HStack(spacing: BTSpacing.md) {
                DashboardStatCard(
                    title: "今日營收",
                    value: Formatters.formatPrice(store.dashboardStats?.todayRevenue ?? 0),
                    icon: "dollarsign.circle.fill",
                    color: BTColor.success
                )
                DashboardStatCard(
                    title: "今日預約",
                    value: "\(store.dashboardStats?.todayBookings ?? 0)",
                    icon: "calendar.badge.clock",
                    color: BTColor.info
                )
            }

            HStack(spacing: BTSpacing.md) {
                DashboardStatCard(
                    title: "待確認",
                    value: "\(store.dashboardStats?.pendingBookings ?? 0)",
                    icon: "clock.badge.questionmark",
                    color: BTColor.warning
                )
                DashboardStatCard(
                    title: "總顧客數",
                    value: "\(store.dashboardStats?.totalCustomers ?? 0)",
                    icon: "person.2.fill",
                    color: BTColor.primary
                )
            }
        }
    }

    // MARK: - Monthly Stats

    private var monthlyStats: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("本月統計")
                .font(.headline)
                .foregroundStyle(BTColor.textPrimary)

            HStack(spacing: BTSpacing.md) {
                BTStatCard(
                    value: Formatters.formatPrice(store.dashboardStats?.monthlyRevenue ?? 0),
                    label: "月營收"
                )
                BTStatCard(
                    value: "\(store.dashboardStats?.monthlyBookings ?? 0)",
                    label: "月預約數"
                )
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("快速操作")
                .font(.headline)
                .foregroundStyle(BTColor.textPrimary)

            HStack(spacing: BTSpacing.md) {
                QuickActionButton(title: "新增服務", icon: "plus.circle.fill", color: BTColor.primary) {
                    showAddService = true
                }
                QuickActionButton(title: "排班", icon: "calendar", color: BTColor.warning) {
                    showSchedule = true
                }
                QuickActionButton(title: "查看訂單", icon: "list.clipboard.fill", color: BTColor.info) {
                    showOrders = true
                }
            }
        }
    }

    // MARK: - Upcoming Bookings

    private var upcomingBookings: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("今日預約")
                .font(.headline)
                .foregroundStyle(BTColor.textPrimary)

            if store.todayBookings.isEmpty {
                ContentUnavailableView(
                    "今日無預約",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("目前沒有今日的預約")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, BTSpacing.xl)
            } else {
                ForEach(store.todayBookings) { booking in
                    BookingMiniCard(booking: booking)
                }
            }
        }
    }
}

// MARK: - Dashboard Stat Card

private struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(BTColor.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(BTColor.textSecondary)
        }
        .padding(BTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .btCard()
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: BTSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(BTColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BTSpacing.lg)
            .background(BTColor.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Booking Mini Card

private struct BookingMiniCard: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(booking.time ?? "--:--")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(BTColor.textPrimary)
                Text(booking.service?.name ?? "未知服務")
                    .font(.subheadline)
                    .foregroundStyle(BTColor.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: BTSpacing.xs) {
                Text(booking.customer?.fullName ?? "顧客")
                    .font(.subheadline)
                    .foregroundStyle(BTColor.textPrimary)
                if let status = booking.status {
                    BTBadge(text: status.displayName, color: status.color)
                }
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(ManageStore())
    }
}
