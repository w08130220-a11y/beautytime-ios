import SwiftUI
import Kingfisher

struct ProviderCard: View {
    let provider: Provider

    var body: some View {
        NavigationLink {
            ProviderDetailView(providerId: provider.id)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Provider image with 4:3 aspect ratio
                ZStack(alignment: .topLeading) {
                    KFImage(URL(string: provider.imageUrl ?? ""))
                        .placeholder {
                            Rectangle()
                                .fill(BTColor.secondaryBackground)
                                .overlay {
                                    Image(systemName: provider.category?.iconName ?? "sparkles")
                                        .font(.title2)
                                        .foregroundStyle(BTColor.primaryLight)
                                }
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .aspectRatio(4/3, contentMode: .fill)
                        .clipped()

                    // Category badge top-left
                    if let category = provider.category {
                        BTBadge(text: category.displayName, color: BTColor.primary)
                            .padding(BTSpacing.sm)
                    }
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: BTRadius.lg,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: BTRadius.lg
                    )
                )

                // Content below image
                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    // Provider name + verified badge
                    HStack(spacing: BTSpacing.xs) {
                        Text(provider.name)
                            .font(.headline)
                            .foregroundStyle(BTColor.textPrimary)
                            .lineLimit(1)

                        if provider.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(BTColor.primary)
                        }
                    }

                    // Location
                    if let city = provider.city {
                        HStack(spacing: BTSpacing.xs) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(city + (provider.district.map { " \($0)" } ?? ""))
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(BTColor.textSecondary)
                    }

                    // Rating
                    HStack(spacing: BTSpacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(BTColor.warning)
                        Text(String(format: "%.1f", provider.rating ?? 0))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(BTColor.textPrimary)
                        Text("(\(provider.reviewCount ?? 0) 則評論)")
                            .font(.caption)
                            .foregroundStyle(BTColor.textSecondary)
                    }
                }
                .padding(BTSpacing.md)
            }
            .btCard()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProviderCard(provider: Provider(
        id: "1",
        userId: nil,
        name: "Beauty Studio",
        category: .nail,
        description: nil,
        address: "台北市大安區忠孝東路100號",
        city: "台北市",
        district: "大安區",
        phone: nil,
        imageUrl: nil,
        rating: 4.5,
        reviewCount: 28,
        isVerified: true,
        isActive: true,
        depositRate: nil,
        instagramUrl: nil,
        reviewNote: nil,
        createdAt: nil
    ))
    .frame(width: 180)
    .padding()
    .background(BTColor.background)
}
