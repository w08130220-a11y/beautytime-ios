import SwiftUI

struct SelectDateTimeStep: View {
    var store: BookingFlowStore

    @State private var displayedMonth = Date()
    @State private var pickerDate = Date()

    private let calendar = Calendar.current

    private var availableDateSet: Set<String> {
        Set(store.availableDates.filter(\.available).map(\.date))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Date Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("選擇日期")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                DatePicker(
                    "日期",
                    selection: $pickerDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .onChange(of: pickerDate) { _, newDate in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let dateString = formatter.string(from: newDate)

                    if availableDateSet.contains(dateString) {
                        store.selectedDate = dateString
                        store.selectedTime = nil
                        store.availableSlots = []
                        Task {
                            await loadSlotsForDate(dateString)
                        }
                    }

                    // Detect month change
                    let newMonth = calendar.component(.month, from: newDate)
                    let oldMonth = calendar.component(.month, from: displayedMonth)
                    if newMonth != oldMonth {
                        displayedMonth = newDate
                        Task {
                            await loadDatesForMonth(newDate)
                        }
                    }
                }
            }

            Divider()

            // MARK: - Time Slots
            VStack(alignment: .leading, spacing: 12) {
                Text("選擇時間")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                if store.selectedDate == nil {
                    Text("請先選擇日期")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else if store.availableSlots.isEmpty {
                    Text("此日期無可用時段")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    timeSlotGrid
                }
            }
        }
        .task {
            await loadDatesForMonth(Date())
        }
    }

    // MARK: - Time Slot Grid

    private var timeSlotGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(store.availableSlots, id: \.self) { slot in
                let isSelected = store.selectedTime == slot
                Button {
                    store.selectedTime = slot
                } label: {
                    Text(slot)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Data Loading

    private func loadDatesForMonth(_ date: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let month = formatter.string(from: date)
        await store.loadAvailableDates(month: month)
    }

    private func loadSlotsForDate(_ dateString: String) async {
        // 載入該日可用員工及時段
        await store.loadAvailableStaff(date: dateString)

        if let selectedStaff = store.selectedStaff,
           let staffEntry = store.availableStaff.first(where: { $0.staff.id == selectedStaff.id }) {
            // 已選設計師 → 顯示該設計師的時段
            store.availableSlots = staffEntry.availableSlots ?? []
        } else {
            // 未選設計師 → 合併所有員工的可用時段（去重排序）
            let allSlots = store.availableStaff.flatMap { $0.availableSlots ?? [] }
            store.availableSlots = Array(Set(allSlots)).sorted()
        }
    }
}

#Preview {
    let store = BookingFlowStore()
    ScrollView {
        SelectDateTimeStep(store: store)
            .padding()
    }
}
