import SwiftUI
import Kingfisher

struct StaffTab: View {
    let providerId: String
    @State private var staff: [StaffMember] = []
    @State private var isLoading = false

    private let api = APIClient.shared

    var body: some View {
        Group {
            if isLoading && staff.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, BTSpacing.xxl)
            } else if staff.isEmpty {
                VStack(spacing: BTSpacing.md) {
                    Image(systemName: "person.2")
                        .font(.largeTitle)
                        .foregroundStyle(BTColor.textTertiary)
                    Text("尚無設計師資訊")
                        .font(.subheadline)
                        .foregroundStyle(BTColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, BTSpacing.xxl)
            } else {
                LazyVStack(spacing: BTSpacing.md) {
                    ForEach(staff) { member in
                        StaffCard(member: member)
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
            }
        }
        .task {
            await loadStaff()
        }
    }

    private func loadStaff() async {
        isLoading = true
        do {
            staff = try await api.get(
                path: APIEndpoints.Staff.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            // Silently handle; empty state shown
        }
        isLoading = false
    }
}

// MARK: - Staff Card

private struct StaffCard: View {
    let member: StaffMember

    var body: some View {
        HStack(spacing: BTSpacing.lg) {
            // Photo
            if let photoUrl = member.photoUrl, let url = URL(string: photoUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(BTColor.secondaryBackground)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Text(String(member.name.prefix(1)))
                            .font(.title3.weight(.medium))
                            .foregroundStyle(BTColor.primary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                HStack(spacing: BTSpacing.sm) {
                    Text(member.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BTColor.textPrimary)

                    if let role = member.role {
                        BTBadge(text: role.displayName, color: BTColor.primary)
                    }
                }

                // Specialties
                if let specialties = member.specialties, !specialties.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BTSpacing.xs) {
                            ForEach(specialties, id: \.self) { specialty in
                                Text(specialty)
                                    .font(.caption2)
                                    .foregroundStyle(BTColor.textSecondary)
                                    .padding(.horizontal, BTSpacing.sm)
                                    .padding(.vertical, 2)
                                    .background(BTColor.background)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Rating
                if let rating = member.rating, rating > 0 {
                    HStack(spacing: BTSpacing.xs) {
                        RatingStars(rating: rating, size: 12)
                        Text(String(format: "%.1f", rating))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(BTColor.textPrimary)
                        if let count = member.reviewCount, count > 0 {
                            Text("(\(count))")
                                .font(.caption)
                                .foregroundStyle(BTColor.textTertiary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(BTSpacing.lg)
        .btCard()
    }
}

#Preview {
    StaffTab(providerId: "1")
}
