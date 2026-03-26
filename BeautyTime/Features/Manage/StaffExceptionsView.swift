import SwiftUI

struct StaffExceptionsView: View {
    @Environment(StaffManageStore.self) private var store

    @State private var showAddSheet = false

    var body: some View {
        List {
            if store.staffExceptions.isEmpty {
                ContentUnavailableView(
                    "尚無休假紀錄",
                    systemImage: "calendar.badge.minus",
                    description: Text("點擊右上角新增員工休假或例外排班")
                )
            } else {
                ForEach(store.staffExceptions) { exception in
                    ExceptionRow(exception: exception, staff: store.staff)
                }
                .onDelete(perform: deleteExceptions)
            }
        }
        .navigationTitle("休假管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("新增休假", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddExceptionSheet(store: store)
        }
        .refreshable {
            let staffIds = store.staff.map(\.id)
            await store.loadStaffExceptions(staffIds: staffIds)
        }
        .task {
            await store.loadStaff()
            let staffIds = store.staff.map(\.id)
            await store.loadStaffExceptions(staffIds: staffIds)
        }
        .alert("錯誤", isPresented: Binding(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("確定") { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
    }

    private func deleteExceptions(at offsets: IndexSet) {
        for index in offsets {
            let exception = store.staffExceptions[index]
            Task {
                await store.deleteStaffException(id: exception.id)
            }
        }
    }
}

// MARK: - Exception Row

private struct ExceptionRow: View {
    let exception: StaffException
    let staff: [StaffMember]

    private var staffName: String {
        staff.first(where: { $0.id == exception.staffId })?.name ?? "未知員工"
    }

    private var reasonDisplay: String {
        switch exception.reason {
        case "sick": return "病假"
        case "vacation": return "休假"
        case "personal": return "事假"
        default: return "其他"
        }
    }

    private var reasonColor: Color {
        switch exception.reason {
        case "sick": return BTColor.error
        case "vacation": return BTColor.info
        case "personal": return BTColor.warning
        default: return BTColor.textSecondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            HStack {
                Text(staffName)
                    .font(.headline)
                Spacer()
                Text(reasonDisplay)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(reasonColor)
                    .padding(.horizontal, BTSpacing.sm)
                    .padding(.vertical, BTSpacing.xs)
                    .background(reasonColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: BTSpacing.sm) {
                Image(systemName: "calendar")
                    .foregroundStyle(BTColor.textSecondary)
                Text(exception.date ?? "")
                    .font(.subheadline)
                    .foregroundStyle(BTColor.textSecondary)

                if let start = exception.startTime, let end = exception.endTime {
                    Text("\(start) ~ \(end)")
                        .font(.subheadline)
                        .foregroundStyle(BTColor.textSecondary)
                }
            }
        }
        .padding(.vertical, BTSpacing.xs)
    }
}

// MARK: - Add Exception Sheet

private struct AddExceptionSheet: View {
    let store: StaffManageStore

    @Environment(\.dismiss) private var dismiss

    @State private var selectedStaff: StaffMember?
    @State private var date = Date()
    @State private var reason = "vacation"
    @State private var note = ""
    @State private var isAllDay = true
    @State private var startTime = StaffScheduleEditView.timeFromString("09:00")
    @State private var endTime = StaffScheduleEditView.timeFromString("18:00")

    private let reasons = [
        ("sick", "病假"),
        ("vacation", "休假"),
        ("personal", "事假"),
        ("other", "其他")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("員工") {
                    Picker("選擇員工", selection: $selectedStaff) {
                        Text("請選擇").tag(nil as StaffMember?)
                        ForEach(store.staff) { member in
                            Text(member.name).tag(member as StaffMember?)
                        }
                    }
                }

                Section("日期") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                Section("類型") {
                    Picker("休假類型", selection: $reason) {
                        ForEach(reasons, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("時間") {
                    Toggle("整天", isOn: $isAllDay)
                    if !isAllDay {
                        DatePicker("開始時間", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("結束時間", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("備註") {
                    TextField("備註（選填）", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新增休假")
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
                    .disabled(selectedStaff == nil)
                }
            }
        }
    }

    private func save() async {
        guard let staff = selectedStaff else { return }

        var body: [String: Any] = [
            "staffId": staff.id,
            "date": Formatters.dateFormatter.string(from: date),
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
}

#Preview {
    NavigationStack {
        StaffExceptionsView()
            .environment(StaffManageStore())
    }
}
