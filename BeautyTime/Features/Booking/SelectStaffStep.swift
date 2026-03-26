import SwiftUI
import Kingfisher

struct SelectStaffStep: View {
    var store: BookingFlowStore

    var body: some View {
        LazyVStack(spacing: 12) {
            // "不指定" option
            anyStaffRow

            if store.isLoading && store.availableStaff.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(store.availableStaff, id: \.staff.id) { available in
                    staffRow(available.staff)
                }
            }
        }
        .task {
            if let date = store.selectedDate {
                await store.loadAvailableStaff(date: date)
            }
        }
    }

    // MARK: - Any Staff Row

    private var anyStaffRow: some View {
        let isSelected = store.selectedStaff == nil

        return Button {
            store.selectedStaff = nil
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.fill.questionmark")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("不指定")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("由系統安排可用設計師")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Staff Row

    private func staffRow(_ staff: StaffMember) -> some View {
        let isSelected = store.selectedStaff?.id == staff.id

        return Button {
            store.selectedStaff = staff
        } label: {
            HStack(spacing: 12) {
                // Photo
                if let photoUrl = staff.photoUrl, let url = URL(string: photoUrl) {
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            staffPlaceholder
                        }
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                } else {
                    staffPlaceholder
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(staff.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if let title = staff.title {
                            Text(title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray5))
                                )
                        }
                    }

                    if let specialties = staff.specialties, !specialties.isEmpty {
                        Text(specialties.joined(separator: " / "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let rating = staff.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let count = staff.reviewCount {
                                Text("(\(count))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var staffPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 52, height: 52)
            Image(systemName: "person.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let store = BookingFlowStore()
    ScrollView {
        SelectStaffStep(store: store)
            .padding()
    }
}
