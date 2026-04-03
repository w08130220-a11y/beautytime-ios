import SwiftUI
import Kingfisher

struct ScheduleView: View {
    @Environment(DashboardStore.self) private var dashboardStore
    @Environment(OrderManageStore.self) private var orderStore
    @Environment(StaffManageStore.self) private var staffStore

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var expandedBookingId: String?
    @State private var viewMode: ViewMode = .month

    private let calendar = Calendar.current

    private enum ViewMode: String, CaseIterable {
        case month = "月曆"
        case day = "日檢視"
    }

    private var selectedDateString: String {
        Formatters.dateFormatter.string(from: selectedDate)
    }

    private var filteredBookings: [Booking] {
        dashboardStore.todayBookings.filter { $0.date == selectedDateString }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("檢視模式", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch viewMode {
            case .month:
                monthCalendarView
            case .day:
                dayDetailView
            }
        }
        .navigationTitle("排班管理")
        .task {
            // 確保 providerId 已設定（ManageView 的 task 可能還沒完成）
            if staffStore.providerId.isEmpty, !dashboardStore.providerId.isEmpty {
                staffStore.providerId = dashboardStore.providerId
            }
            await staffStore.loadStaff()
            if !staffStore.staff.isEmpty {
                let staffIds = staffStore.staff.map(\.id)
                await staffStore.loadStaffSchedules(staffIds: staffIds)
                await staffStore.loadStaffExceptions(staffIds: staffIds)
            }
            await dashboardStore.loadDashboard()
        }
    }

    // MARK: - Month Calendar

    private var monthCalendarView: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                // Month navigation
                HStack {
                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(monthYearString(displayedMonth))
                        .font(.headline)

                    Spacer()

                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Day of week headers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    // Calendar days
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date {
                            CalendarDayCell(
                                date: date,
                                staff: staffStore.staff,
                                staffSchedules: staffStore.staffSchedules,
                                staffExceptions: staffStore.staffExceptions,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date)
                            )
                            .onTapGesture {
                                selectedDate = date
                                viewMode = .day
                            }
                        } else {
                            Color.clear.frame(height: 60)
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Staff legend
                staffLegend
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Day Detail

    private var dayDetailView: some View {
        VStack(spacing: 0) {
            // Date navigation
            HStack {
                Button {
                    selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(Formatters.displayDate(selectedDate))
                    .font(.headline)

                Spacer()

                Button {
                    selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            Divider()

            // Bookings for selected day
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
                                    Task { await orderStore.confirmBooking(id: booking.id) }
                                },
                                onComplete: {
                                    Task { await orderStore.completeBooking(id: booking.id) }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Staff Legend

    private var staffLegend: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text("員工圖示")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 12) {
                ForEach(staffStore.staff) { member in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(staffColor(for: member))
                            .frame(width: 8, height: 8)
                        Text(member.name)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }

        let firstDay = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmpty = firstWeekday - 1

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)

        for dayOffset in range {
            if let date = calendar.date(byAdding: .day, value: dayOffset - 1, to: firstDay) {
                days.append(date)
            }
        }

        return days
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-TW")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    private func staffColor(for member: StaffMember) -> Color {
        let colors: [Color] = [.blue, .red, .green, .orange, .purple, .cyan, .pink, .mint]
        guard let index = staffStore.staff.firstIndex(where: { $0.id == member.id }) else {
            return .gray
        }
        return colors[index % colors.count]
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let staff: [StaffMember]
    let staffSchedules: [String: [StaffSchedule]]
    let staffExceptions: [StaffException]
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current
    private let colors: [Color] = [.blue, .red, .green, .orange, .purple, .cyan, .pink, .mint]

    private var dateString: String {
        Formatters.dateFormatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : (isToday ? BTColor.primary : .primary))

            // Staff working dots + leave markers
            HStack(spacing: 2) {
                ForEach(Array(workingStaff.prefix(3).enumerated()), id: \.offset) { _, member in
                    let onLeave = staffExceptions.contains { $0.staffId == member.id && $0.date == dateString }
                    if onLeave {
                        Image(systemName: "xmark")
                            .font(.system(size: 5, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(width: 5, height: 5)
                    } else {
                        Circle()
                            .fill(colorForStaff(member))
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(isSelected ? BTColor.primary : (isToday ? BTColor.primary.opacity(0.1) : Color.clear))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var workingStaff: [StaffMember] {
        let dayOfWeek = calendar.component(.weekday, from: date) - 1 // 0=Sun
        return staff.filter { member in
            // 有請假 → 仍然顯示（用 x 標記），讓管理者看到
            guard let schedules = staffSchedules[member.id] else {
                return true
            }
            return schedules.contains { schedule in
                schedule.dayOfWeek == dayOfWeek && (schedule.isAvailable == true)
            }
        }
    }

    private func colorForStaff(_ member: StaffMember) -> Color {
        guard let index = staff.firstIndex(where: { $0.id == member.id }) else { return .gray }
        return colors[index % colors.count]
    }
}

// MARK: - Flow Layout (for staff legend)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
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

                    Divider().frame(height: 36)

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
            .environment(StaffManageStore())
    }
}
