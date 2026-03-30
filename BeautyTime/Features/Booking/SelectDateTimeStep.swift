import SwiftUI

struct SelectDateStep: View {
    var store: BookingFlowStore

    @State private var displayedMonth = Date()
    @State private var pickerDate = Date()

    private let calendar = Calendar.current

    private var availableDateSet: Set<String> {
        Set(store.availableDates.filter(\.available).map(\.date))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("選擇預約日期")
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
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let dateString = formatter.string(from: newDate)

                if availableDateSet.contains(dateString) {
                    store.selectedDate = dateString
                    // 清除前一次選擇的設計師和時段
                    store.selectedStaff = nil
                    store.selectedTime = nil
                    store.staffFindResult = nil
                } else {
                    store.selectedDate = nil
                }

                // 偵測月份變更
                let newMonth = calendar.component(.month, from: newDate)
                let oldMonth = calendar.component(.month, from: displayedMonth)
                if newMonth != oldMonth {
                    displayedMonth = newDate
                    Task {
                        await loadDatesForMonth(newDate)
                    }
                }
            }

            // 選擇狀態
            if let date = store.selectedDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("已選擇：\(date)")
                        .font(.subheadline)
                }
                .padding(.horizontal)
            } else if !store.isLoading && !store.availableDates.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.orange)
                    Text("請點選綠色標示的可用日期")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            if store.isLoading {
                ProgressView("載入可用日期...")
                    .frame(maxWidth: .infinity)
            }
        }
        .task {
            await loadDatesForMonth(Date())
        }
    }

    private func loadDatesForMonth(_ date: Date) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let month = formatter.string(from: date)
        await store.loadAvailableDates(month: month)
    }
}

#Preview {
    let store = BookingFlowStore()
    ScrollView {
        SelectDateStep(store: store)
            .padding()
    }
}
