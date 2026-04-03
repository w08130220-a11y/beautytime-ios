import SwiftUI

// MARK: - BeautyTime Design System

enum BTColor {
    // Primary
    static let primary = Color(hex: "E8835C")
    static let primaryLight = Color(hex: "F2A88A")
    static let primaryDark = Color(hex: "C96A45")

    // Background
    static let background = Color(hex: "FFF8F0")
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(hex: "FFF0E6")

    // Text
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Status
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "3B82F6")

    // Border
    static let border = Color(.separator)
    static let borderLight = Color.primary.opacity(0.1)
}

enum BTSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum BTRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct BTCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(BTColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.lg)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct BTPrimaryButtonModifier: ViewModifier {
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? BTColor.primary.opacity(0.4) : BTColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }
}

struct BTSecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontWeight(.medium)
            .foregroundStyle(BTColor.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(BTColor.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
    }
}

struct BTPageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(BTColor.background)
    }
}

// MARK: - View Extensions

extension View {
    func btCard() -> some View {
        modifier(BTCardModifier())
    }

    func btPrimaryButton(isDisabled: Bool = false) -> some View {
        modifier(BTPrimaryButtonModifier(isDisabled: isDisabled))
    }

    func btSecondaryButton() -> some View {
        modifier(BTSecondaryButtonModifier())
    }

    func btPageBackground() -> some View {
        modifier(BTPageBackground())
    }
}

// MARK: - Reusable Components

struct BTBadge: View {
    let text: String
    var color: Color = BTColor.primary

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, BTSpacing.sm)
            .padding(.vertical, BTSpacing.xs)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct BTStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: BTSpacing.xs) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(BTColor.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(BTColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BTSpacing.lg)
        .btCard()
    }
}

struct BTMenuRow: View {
    let icon: String
    let title: String
    var trailingText: String? = nil

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BTColor.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(.body)

            Spacer()

            if let trailing = trailingText {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
            }

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(BTColor.textTertiary)
        }
        .padding(.vertical, BTSpacing.md)
    }
}

struct BTSectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(BTColor.background)
            .frame(height: BTSpacing.sm)
    }
}
