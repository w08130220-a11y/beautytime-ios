import SwiftUI
import Kingfisher

struct SelectStaffTimeStep: View {
    var store: BookingFlowStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - 設計師選擇
            VStack(alignment: .leading, spacing: 12) {
                Text("選擇設計師")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                if store.isLoading && store.staffFindResult == nil {
                    ProgressView("載入可用設計師...")
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else if let result = store.staffFindResult, !result.staff.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // 不指定
                            staffChip(name: "不指定", icon: "person.fill.questionmark", isSelected: store.selectedStaff == nil) {
                                store.selectedStaff = nil
                                store.selectedTime = nil
                            }

                            // 設計師列表
                            ForEach(result.staff, id: \.id) { member in
                                let hasSlots = !(result.availableSlots[member.id]?.filter(\.available).isEmpty ?? true)
                                staffChip(
                                    name: member.name,
                                    photoUrl: member.photoUrl,
                                    isSelected: store.selectedStaff?.id == member.id,
                                    disabled: !hasSlots
                                ) {
                                    store.selectedStaff = member
                                    store.selectedTime = nil
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } else {
                    Text("此日期無可用設計師")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
            }

            Divider()

            // MARK: - 時段選擇
            VStack(alignment: .leading, spacing: 12) {
                Text("選擇時段")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                let slots = store.currentAllSlots
                if slots.isEmpty && !store.isLoading {
                    Text("無可用時段")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    timeSlotGrid(slots: slots)
                }
            }
        }
        .task {
            await store.loadAvailableStaffForDate()
        }
    }

    // MARK: - Staff Chip

    private func staffChip(
        name: String,
        icon: String? = nil,
        photoUrl: String? = nil,
        isSelected: Bool,
        disabled: Bool = false,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 6) {
                if let photoUrl, let url = URL(string: photoUrl) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Circle().fill(Color(.systemGray5))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.secondary)
                                }
                        }
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray5))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: icon ?? "person.fill")
                                .font(.title3)
                                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        }
                }

                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(disabled ? .tertiary : .primary)
                    .lineLimit(1)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    // MARK: - Time Slot Grid

    private func timeSlotGrid(slots: [StaffTimeSlot]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(slots, id: \.time) { slot in
                let isSelected = store.selectedTime == slot.time
                let isAvailable = slot.available
                Button {
                    store.selectedTime = slot.time
                } label: {
                    Text(slot.time)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(
                            isSelected ? .white :
                            isAvailable ? .primary : .tertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    isSelected ? Color.accentColor :
                                    isAvailable ? Color(.secondarySystemGroupedBackground) :
                                    Color(.systemGray6)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isSelected ? Color.accentColor :
                                    isAvailable ? Color(.systemGray4) :
                                    Color(.systemGray5),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isAvailable)
            }
        }
    }
}

#Preview {
    let store = BookingFlowStore()
    ScrollView {
        SelectStaffTimeStep(store: store)
            .padding()
    }
}
