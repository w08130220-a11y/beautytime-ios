import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜尋..."
    var onSubmit: (() -> Void)?

    var body: some View {
        HStack(spacing: BTSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(BTColor.textSecondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit { onSubmit?() }
            if !text.isEmpty {
                Button {
                    text = ""
                    onSubmit?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(BTColor.textSecondary)
                }
            }
        }
        .padding(BTSpacing.md)
        .background(BTColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: BTRadius.md)
                .stroke(BTColor.border, lineWidth: 1)
        )
    }
}

struct RatingStars: View {
    let rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(BTColor.warning)
            }
        }
    }

    private func starType(for index: Int) -> String {
        if Double(index) <= rating {
            return "star.fill"
        } else if Double(index) - 0.5 <= rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct RatingInput: View {
    @Binding var rating: Int
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(BTColor.warning)
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}
