import SwiftUI

struct TimeSlotBlockView: View {
    @Environment(StaffManageStore.self) private var store

    @State private var selectedStaff: StaffMember?
    @State private var date = Date()
    @State private var startTime = StaffScheduleEditView.timeFromString("09:00")
    @State private var endTime = StaffScheduleEditView.timeFromString("10:00")

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
                Section("新增封鎖時段") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    DatePicker("開始時間", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("結束時間", selection: $endTime, displayedComponents: .hourAndMinute)

                    Button {
                        Task { await addBlock() }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("新增封鎖")
                        }
                        .foregroundStyle(BTColor.primary)
                    }
                    .disabled(store.isLoading)
                }

                Section("已封鎖時段") {
                    if store.timeSlots.isEmpty {
                        ContentUnavailableView(
                            "尚無封鎖時段",
                            systemImage: "clock.badge.xmark",
                            description: Text("選擇日期與時間來封鎖時段")
                        )
                    } else {
                        ForEach(store.timeSlots) { slot in
                            TimeSlotRow(slot: slot)
                        }
                        .onDelete(perform: deleteSlots)
                    }
                }
            }
        }
        .navigationTitle("封鎖時段")
        .task {
            await store.loadStaff()
        }
        .onChange(of: selectedStaff) { _, newValue in
            if let staff = newValue {
                Task { await loadSlots(for: staff.id) }
            }
        }
        .onChange(of: date) { _, _ in
            if let staff = selectedStaff {
                Task { await loadSlots(for: staff.id) }
            }
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

    private func loadSlots(for staffId: String) async {
        let dateStr = Formatters.dateFormatter.string(from: date)
        await store.loadTimeSlots(staffId: staffId, dates: [dateStr])
    }

    private func addBlock() async {
        guard let staff = selectedStaff else { return }

        await store.createTimeSlot(
            staffId: staff.id,
            date: Formatters.dateFormatter.string(from: date),
            startTime: Formatters.timeFormatter.string(from: startTime),
            endTime: Formatters.timeFormatter.string(from: endTime)
        )
    }

    private func deleteSlots(at offsets: IndexSet) {
        for index in offsets {
            let slot = store.timeSlots[index]
            Task {
                await store.deleteTimeSlot(id: slot.id)
            }
        }
    }
}

// MARK: - Time Slot Row

private struct TimeSlotRow: View {
    let slot: TimeSlot

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: "clock.badge.xmark")
                .foregroundStyle(BTColor.error)

            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(slot.date ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let start = slot.startTime, let end = slot.endTime {
                    Text("\(start) ~ \(end)")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, BTSpacing.xs)
    }
}

#Preview {
    NavigationStack {
        TimeSlotBlockView()
            .environment(StaffManageStore())
    }
}
