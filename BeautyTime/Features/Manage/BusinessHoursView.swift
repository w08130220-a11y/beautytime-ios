import SwiftUI

struct BusinessHoursView: View {
    @Environment(ManageStore.self) private var store

    @State private var editableHours: [EditableBusinessHour] = []
    @State private var isSaving = false

    private let dayNames = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]

    var body: some View {
        List {
            ForEach($editableHours) { $hour in
                BusinessHourRow(hour: $hour, dayName: dayNames[hour.dayOfWeek])
            }

            Section {
                Button {
                    Task { await saveHours() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("儲存")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("營業時間")
        .task {
            await store.loadBusinessHours()
            populateEditableHours()
        }
    }

    private func populateEditableHours() {
        if store.businessHours.isEmpty {
            // Create default 7-day entries
            editableHours = (0...6).map { day in
                EditableBusinessHour(
                    id: UUID().uuidString,
                    dayOfWeek: day,
                    isOpen: day >= 1 && day <= 5,
                    openTime: dateFrom(timeString: "09:00"),
                    closeTime: dateFrom(timeString: "18:00")
                )
            }
        } else {
            editableHours = store.businessHours.map { bh in
                EditableBusinessHour(
                    id: bh.id,
                    dayOfWeek: bh.dayOfWeek,
                    isOpen: bh.isOpen ?? false,
                    openTime: dateFrom(timeString: bh.openTime ?? "09:00"),
                    closeTime: dateFrom(timeString: bh.closeTime ?? "18:00")
                )
            }.sorted { $0.dayOfWeek < $1.dayOfWeek }
        }
    }

    private func saveHours() async {
        isSaving = true
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let hours = editableHours.map { eh in
            BusinessHour(
                id: eh.id,
                providerId: store.providerId,
                dayOfWeek: eh.dayOfWeek,
                openTime: formatter.string(from: eh.openTime),
                closeTime: formatter.string(from: eh.closeTime),
                isOpen: eh.isOpen
            )
        }

        await store.updateBusinessHours(hours)
        isSaving = false
    }

    private func dateFrom(timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? formatter.date(from: "09:00")!
    }
}

// MARK: - Editable Model

private struct EditableBusinessHour: Identifiable {
    let id: String
    let dayOfWeek: Int
    var isOpen: Bool
    var openTime: Date
    var closeTime: Date
}

// MARK: - Business Hour Row

private struct BusinessHourRow: View {
    @Binding var hour: EditableBusinessHour
    let dayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayName)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $hour.isOpen)
                    .labelsHidden()
            }

            if hour.isOpen {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("開始")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $hour.openTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    VStack(alignment: .leading) {
                        Text("結束")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $hour.closeTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            } else {
                Text("休息")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BusinessHoursView()
            .environment(ManageStore())
    }
}
