import SwiftUI

struct StaffScheduleEditView: View {
    @Environment(StaffManageStore.self) private var store

    @State private var selectedStaff: StaffMember?
    @State private var dayEntries: [DayEntry] = Self.defaultEntries()
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var saveError: String?

    var body: some View {
        Form {
            Section("選擇員工") {
                Picker("員工", selection: $selectedStaff) {
                    Text("請選擇").tag(nil as StaffMember?)
                    ForEach(store.staff) { member in
                        Text(member.name).tag(member as StaffMember?)
                    }
                }
            }

            if selectedStaff != nil {
                Section("每週排班") {
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
                        Task { await saveSchedule() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "儲存中..." : "儲存排班")
                        }
                        .btPrimaryButton()
                    }
                    .disabled(isSaving)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("排班設定")
        .task {
            await store.loadStaff()
        }
        .onChange(of: selectedStaff) { _, newValue in
            if let staff = newValue {
                Task { await loadScheduleForStaff(staff.id) }
            }
        }
        .alert("儲存成功", isPresented: $showSuccess) {
            Button("確定") {}
        } message: {
            Text("\(selectedStaff?.name ?? "員工")的排班已更新")
        }
        .alert("儲存失敗", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("確定") { saveError = nil }
        } message: {
            Text(saveError ?? "未知錯誤")
        }
    }

    private func loadScheduleForStaff(_ staffId: String) async {
        await store.loadStaffSchedules(staffIds: [staffId])
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

    private func saveSchedule() async {
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

    // MARK: - Helpers

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
