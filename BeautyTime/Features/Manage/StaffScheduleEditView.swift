import SwiftUI

struct StaffScheduleEditView: View {
    @Environment(StaffManageStore.self) private var store

    @State private var selectedStaff: StaffMember?
    @State private var activeTab: ScheduleTab = .weekly
    // Weekly
    @State private var dayEntries: [DayEntry] = Self.defaultEntries()
    @State private var isSaving = false
    @State private var showSuccess = false
    // Leave
    @State private var showAddLeave = false
    @State private var displayedMonth = Date()
    // Feedback
    @State private var saveError: String?

    private let calendar = Calendar.current

    enum ScheduleTab: String, CaseIterable {
        case weekly = "每週預設"
        case leave = "請假 / 調班"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Staff picker
            staffPicker
                .padding()

            if selectedStaff != nil {
                Picker("模式", selection: $activeTab) {
                    ForEach(ScheduleTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                switch activeTab {
                case .weekly:
                    weeklyScheduleView
                case .leave:
                    leaveManagementView
                }
            } else {
                ContentUnavailableView(
                    "請先選擇員工",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("選擇員工後即可設定排班與請假")
                )
            }
        }
        .navigationTitle("排班設定")
        .task { await store.loadStaff() }
        .onChange(of: selectedStaff) { _, newValue in
            if let staff = newValue {
                Task {
                    await store.loadStaffSchedules(staffIds: [staff.id])
                    await store.loadStaffExceptions(staffIds: [staff.id])
                    loadScheduleForStaff(staff.id)
                }
            }
        }
        .alert("儲存成功", isPresented: $showSuccess) {
            Button("確定") {}
        } message: {
            Text("\(selectedStaff?.name ?? "員工")的排班已更新")
        }
        .alert("錯誤", isPresented: Binding(
            get: { saveError != nil || store.error != nil },
            set: { if !$0 { saveError = nil; store.error = nil } }
        )) {
            Button("確定") { saveError = nil; store.error = nil }
        } message: {
            Text(saveError ?? store.error ?? "未知錯誤")
        }
        .sheet(isPresented: $showAddLeave) {
            AddLeaveSheet(store: store, selectedStaff: selectedStaff)
        }
    }

    // MARK: - Staff Picker

    private var staffPicker: some View {
        HStack {
            Text("員工")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Picker("員工", selection: $selectedStaff) {
                Text("請選擇").tag(nil as StaffMember?)
                ForEach(store.staff) { member in
                    Text(member.name).tag(member as StaffMember?)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Schedule

    private var weeklyScheduleView: some View {
        List {
            Section("每週固定班表") {
                ForEach($dayEntries) { $entry in
                    VStack(alignment: .leading, spacing: BTSpacing.sm) {
                        Toggle(entry.dayName, isOn: $entry.isWorking)
                            .fontWeight(.medium)

                        if entry.isWorking {
                            HStack {
                                DatePicker("開始", selection: $entry.startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                Text("~")
                                    .foregroundStyle(BTColor.textSecondary)
                                DatePicker("結束", selection: $entry.endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }
                    .padding(.vertical, BTSpacing.xs)
                }
            }

            Section {
                Button {
                    Task { await saveWeeklySchedule() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView().tint(.white)
                        }
                        Text(isSaving ? "儲存中..." : "儲存每週排班")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                Text("每週預設班表是基礎模板，適用於所有未來日期。如需針對特定日期調整，請切換到「請假 / 調班」。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Leave Management

    private var leaveManagementView: some View {
        List {
            // Month Calendar
            Section("月曆總覽") {
                leaveCalendarView
            }

            // Add leave button
            Section {
                Button {
                    showAddLeave = true
                } label: {
                    Label("新增請假 / 調班", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Existing exceptions
            Section("已排定的請假 / 調班") {
                let staffExceptions = filteredExceptions
                if staffExceptions.isEmpty {
                    Text("尚無請假或調班紀錄")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    ForEach(staffExceptions) { exception in
                        LeaveRow(exception: exception)
                    }
                    .onDelete { offsets in
                        deleteExceptions(offsets, from: staffExceptions)
                    }
                }
            }
        }
    }

    // MARK: - Leave Calendar

    private var leaveCalendarView: some View {
        VStack(spacing: 12) {
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

            // Day headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ForEach(daysInMonth(), id: \.self) { date in
                    if let date {
                        let status = dayStatus(for: date)
                        VStack(spacing: 2) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.caption)
                                .foregroundStyle(status == .leave ? .white : .primary)

                            Circle()
                                .fill(status.color)
                                .frame(width: 4, height: 4)
                                .opacity(status == .normal ? 0 : 1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(status == .leave ? BTColor.error.opacity(0.8) : Color.clear)
                        )
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .green, label: "上班")
                legendItem(color: BTColor.error, label: "請假")
                legendItem(color: .gray.opacity(0.4), label: "休息")
            }
            .font(.caption2)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var filteredExceptions: [StaffException] {
        guard let staffId = selectedStaff?.id else { return [] }
        return store.staffExceptions
            .filter { $0.staffId == staffId }
            .sorted { ($0.date ?? "") > ($1.date ?? "") }
    }

    private enum DayStatus {
        case working, off, leave, normal

        var color: Color {
            switch self {
            case .working: return .green
            case .off: return .gray.opacity(0.4)
            case .leave: return BTColor.error
            case .normal: return .clear
            }
        }
    }

    private func dayStatus(for date: Date) -> DayStatus {
        let dateString = Formatters.dateFormatter.string(from: date)

        // Check exceptions first
        if let staffId = selectedStaff?.id {
            let hasLeave = store.staffExceptions.contains {
                $0.staffId == staffId && $0.date == dateString
            }
            if hasLeave { return .leave }
        }

        // Check weekly schedule
        let dayOfWeek = calendar.component(.weekday, from: date) - 1 // 0=Sun
        if let staffId = selectedStaff?.id,
           let schedules = store.staffSchedules[staffId] {
            let isWorking = schedules.contains {
                $0.dayOfWeek == dayOfWeek && $0.isAvailable == true
            }
            return isWorking ? .working : .off
        }

        return .normal
    }

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

    private func loadScheduleForStaff(_ staffId: String) {
        let schedules = store.staffSchedules[staffId] ?? []
        var entries = Self.defaultEntries()
        for schedule in schedules {
            guard let dow = schedule.dayOfWeek, dow >= 0, dow < 7 else { continue }
            let entryIndex = dow == 0 ? 6 : dow - 1
            entries[entryIndex].isWorking = schedule.isAvailable ?? false
            if let start = schedule.startTime {
                entries[entryIndex].startTime = Self.timeFromString(start)
            }
            if let end = schedule.endTime {
                entries[entryIndex].endTime = Self.timeFromString(end)
            }
        }
        dayEntries = entries
    }

    private func saveWeeklySchedule() async {
        guard let staff = selectedStaff else { return }
        isSaving = true
        store.error = nil

        let schedules: [[String: Any]] = dayEntries.enumerated().map { index, entry in
            let apiDow = index == 6 ? 0 : index + 1
            return [
                "dayOfWeek": apiDow,
                "isWorking": entry.isWorking,
                "startTime": Formatters.timeFormatter.string(from: entry.startTime),
                "endTime": Formatters.timeFormatter.string(from: entry.endTime)
            ] as [String: Any]
        }

        await store.updateStaffSchedule(staffId: staff.id, schedules: schedules)
        isSaving = false

        if let error = store.error {
            saveError = error
            store.error = nil
        } else {
            showSuccess = true
        }
    }

    private func deleteExceptions(_ offsets: IndexSet, from list: [StaffException]) {
        for index in offsets {
            let exception = list[index]
            Task { await store.deleteStaffException(id: exception.id) }
        }
    }

    // MARK: - Static Helpers

    static func defaultEntries() -> [DayEntry] {
        let dayNames = ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]
        let defaultStart = timeFromString("09:00")
        let defaultEnd = timeFromString("18:00")
        return dayNames.enumerated().map { index, name in
            DayEntry(
                dayIndex: index,
                dayName: name,
                isWorking: index < 5,
                startTime: defaultStart,
                endTime: defaultEnd
            )
        }
    }

    static func timeFromString(_ str: String) -> Date {
        Formatters.timeFormatter.date(from: str) ?? Date()
    }
}

// MARK: - Leave Row

private struct LeaveRow: View {
    let exception: StaffException

    private var reasonDisplay: (String, Color) {
        switch exception.reason ?? exception.type ?? "" {
        case "sick": return ("病假", BTColor.error)
        case "vacation": return ("休假", BTColor.info)
        case "personal": return ("事假", BTColor.warning)
        case "bereavement": return ("喪假", .purple)
        case "annual": return ("特休", .teal)
        case "swap": return ("調班", .orange)
        default: return ("其他", BTColor.textSecondary)
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(exception.date ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let start = exception.startTime, let end = exception.endTime {
                        Text("\(start)~\(end)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("整天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let note = exception.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(reasonDisplay.0)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(reasonDisplay.1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(reasonDisplay.1.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Add Leave Sheet

private struct AddLeaveSheet: View {
    let store: StaffManageStore
    let selectedStaff: StaffMember?

    @Environment(\.dismiss) private var dismiss

    @State private var dates: Set<DateComponents> = []
    @State private var reason = "personal"
    @State private var note = ""
    @State private var isAllDay = true
    @State private var startTime = StaffScheduleEditView.timeFromString("09:00")
    @State private var endTime = StaffScheduleEditView.timeFromString("18:00")
    @State private var isSaving = false

    private let reasons = [
        ("personal", "事假"),
        ("sick", "病假"),
        ("bereavement", "喪假"),
        ("annual", "特休"),
        ("vacation", "休假"),
        ("swap", "調班"),
        ("other", "其他")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("員工") {
                    Text(selectedStaff?.name ?? "未選擇")
                        .foregroundStyle(selectedStaff == nil ? .secondary : .primary)
                }

                Section("選擇日期（可多選）") {
                    MultiDatePicker("日期", selection: $dates)
                }

                Section("假別") {
                    Picker("類型", selection: $reason) {
                        ForEach(reasons, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("時間") {
                    Toggle("整天", isOn: $isAllDay)
                    if !isAllDay {
                        DatePicker("開始", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("結束", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("備註") {
                    TextField("備註（選填）", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("新增請假")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("新增") {
                        Task {
                            await save()
                            dismiss()
                        }
                    }
                    .disabled(selectedStaff == nil || dates.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        guard let staff = selectedStaff else { return }
        isSaving = true

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for dateComponents in dates {
            guard let date = Calendar.current.date(from: dateComponents) else { continue }
            let dateString = dateFormatter.string(from: date)

            var body: [String: Any] = [
                "staffId": staff.id,
                "date": dateString,
                "type": reason,
                "reason": reason,
                "isBlocked": true
            ]

            if !isAllDay {
                body["startTime"] = Formatters.timeFormatter.string(from: startTime)
                body["endTime"] = Formatters.timeFormatter.string(from: endTime)
            }

            if !note.isEmpty {
                body["note"] = note
            }

            await store.createStaffException(body)
        }

        isSaving = false
    }
}

// MARK: - Day Entry

struct DayEntry: Identifiable {
    let id = UUID()
    let dayIndex: Int
    let dayName: String
    var isWorking: Bool
    var startTime: Date
    var endTime: Date
}

extension StaffMember: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: StaffMember, rhs: StaffMember) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    NavigationStack {
        StaffScheduleEditView()
            .environment(StaffManageStore())
    }
}
