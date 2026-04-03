import SwiftUI
import Kingfisher

struct ReviewsSection: View {
    let reviews: [Review]
    var showAll: Bool = false
    /// Set to true to enable merchant reply functionality
    var allowReply: Bool = false
    var onReply: ((String, String) -> Void)? // (reviewId, content)

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
                    ReviewCard(
                        review: review,
                        allowReply: allowReply,
                        onReply: onReply
                    )
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
    var allowReply: Bool = false
    var onReply: ((String, String) -> Void)?

    @State private var showReplyField = false
    @State private var replyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Customer header
            HStack(spacing: 10) {
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

            // Comment
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

            // Merchant reply (if exists)
            if let reply = review.reply {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption)
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("商家回覆")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.accent)
                        Text(reply.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let date = reply.createdAt {
                            Text(Formatters.relativeDate(date))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Reply button (merchant only, no existing reply)
            if allowReply && review.reply == nil {
                if showReplyField {
                    VStack(spacing: 8) {
                        TextField("回覆這則評論...", text: $replyText, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)

                        HStack {
                            Button("取消") {
                                showReplyField = false
                                replyText = ""
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                guard !replyText.isEmpty else { return }
                                onReply?(review.id, replyText)
                                showReplyField = false
                                replyText = ""
                            } label: {
                                Text("送出回覆")
                                    .font(.caption.weight(.medium))
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(replyText.isEmpty)
                        }
                    }
                } else {
                    Button {
                        showReplyField = true
                    } label: {
                        Label("回覆", systemImage: "arrowshape.turn.up.left")
                            .font(.caption)
                            .foregroundStyle(.accent)
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
    ReviewsSection(
        reviews: [
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
                ),
                reply: ReviewReply(
                    id: "r1",
                    reviewId: "1",
                    content: "謝謝您的好評！期待下次為您服務 ❤️",
                    createdAt: Date()
                )
            )
        ],
        allowReply: true
    )
    .padding()
}
