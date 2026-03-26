import SwiftUI
import Kingfisher

struct ReviewsSection: View {
    let reviews: [Review]
    var showAll: Bool = false
    @State private var isExpanded = false

    private var visibleReviews: [Review] {
        if showAll || isExpanded {
            return reviews
        }
        return Array(reviews.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if reviews.isEmpty {
                Text("尚無評論")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 32)
            } else {
                ForEach(visibleReviews) { review in
                    ReviewCard(review: review)
                }

                if !showAll && reviews.count > 3 && !isExpanded {
                    Button {
                        withAnimation {
                            isExpanded = true
                        }
                    } label: {
                        HStack {
                            Text("查看全部 \(reviews.count) 則評論")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

// MARK: - Review Card

private struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Avatar
                if let avatarUrl = review.customer?.avatarUrl, let url = URL(string: avatarUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text(String((review.customer?.fullName ?? "?").prefix(1)))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.customer?.fullName ?? "匿名使用者")
                        .font(.subheadline.weight(.medium))
                    if let date = review.createdAt {
                        Text(Formatters.relativeDate(date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                RatingStars(rating: Double(review.rating), size: 12)
            }

            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            // Review images
            if let imageUrls = review.imageUrls, !imageUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(imageUrls, id: \.self) { urlString in
                            KFImage(URL(string: urlString))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ReviewsSection(reviews: [
        Review(
            id: "1",
            bookingId: nil,
            customerId: nil,
            providerId: nil,
            staffId: nil,
            rating: 5,
            comment: "很棒的服務！",
            imageUrls: nil,
            createdAt: Date(),
            customer: User(
                id: "u1",
                email: "test@example.com",
                fullName: "小美",
                avatarUrl: nil,
                phone: nil,
                phoneVerified: nil,
                role: .customer,
                preferredLocale: nil,
                surveyCompleted: nil,
                createdAt: nil
            )
        )
    ])
    .padding()
}
