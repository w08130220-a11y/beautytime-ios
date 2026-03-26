import SwiftUI

struct PerformanceView: View {
    @Environment(StaffManageStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if store.staffPerformance.isEmpty {
                    ContentUnavailableView(
                        "尚無績效資料",
                        systemImage: "chart.bar.xaxis",
                        description: Text("目前沒有員工績效數據")
                    )
                } else {
                    summarySection
                    staffListSection
                }
            }
            .padding(BTSpacing.lg)
        }
        .btPageBackground()
        .navigationTitle("員工績效分析")
        .task {
            await store.loadStaffPerformance()
        }
        .refreshable {
            await store.loadStaffPerformance()
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: BTSpacing.md) {
            BTStatCard(
                value: "\(store.staffPerformance.count)",
                label: "員工人數"
            )
            BTStatCard(
                value: Formatters.formatPrice(Double(totalRevenue)),
                label: "總營收"
            )
            BTStatCard(
                value: "\(totalBookings)",
                label: "總預約數"
            )
        }
    }

    private var totalRevenue: Int {
        Int(store.staffPerformance.compactMap(\.revenue).reduce(0, +))
    }

    private var totalBookings: Int {
        store.staffPerformance.compactMap(\.bookingCount).reduce(0, +)
    }

    private var maxRevenue: Double {
        store.staffPerformance.compactMap(\.revenue).max() ?? 1
    }

    private var maxBookings: Int {
        store.staffPerformance.compactMap(\.bookingCount).max() ?? 1
    }

    // MARK: - Staff List

    private var staffListSection: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            Text("個人績效")
                .font(.headline)
                .foregroundStyle(BTColor.textPrimary)

            ForEach(store.staffPerformance) { staff in
                StaffPerformanceCard(
                    staff: staff,
                    maxRevenue: maxRevenue,
                    maxBookings: maxBookings
                )
            }
        }
    }
}

// MARK: - Staff Performance Card

private struct StaffPerformanceCard: View {
    let staff: StaffPerformance
    let maxRevenue: Double
    let maxBookings: Int

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    Text(staff.name ?? "未知員工")
                        .font(.headline)
                        .foregroundStyle(BTColor.textPrimary)

                    HStack(spacing: BTSpacing.sm) {
                        if let rating = staff.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(BTColor.warning)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .foregroundStyle(BTColor.textSecondary)
                            }
                        }
                        if let reviewCount = staff.reviewCount {
                            Text("\(reviewCount) 則評價")
                                .font(.caption)
                                .foregroundStyle(BTColor.textTertiary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: BTSpacing.xs) {
                    Text(Formatters.formatPrice(staff.revenue ?? 0))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(BTColor.primary)
                    Text("\(staff.bookingCount ?? 0) 筆預約")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }
            }

            // Revenue bar
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text("營收")
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
                PerformanceBar(
                    value: staff.revenue ?? 0,
                    maxValue: maxRevenue,
                    color: BTColor.primary
                )
            }

            // Bookings bar
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text("預約數")
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
                PerformanceBar(
                    value: Double(staff.bookingCount ?? 0),
                    maxValue: Double(maxBookings),
                    color: BTColor.info
                )
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }
}

// MARK: - Performance Bar

private struct PerformanceBar: View {
    let value: Double
    let maxValue: Double
    let color: Color

    private var ratio: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value / maxValue)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.15))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * ratio, height: 8)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    NavigationStack {
        PerformanceView()
            .environment(StaffManageStore())
    }
}
