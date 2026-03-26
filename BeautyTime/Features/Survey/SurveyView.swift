import SwiftUI

struct SurveyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore

    @State private var currentStep = 0
    @State private var selectedCategories: Set<ServiceCategory> = []
    @State private var selectedCity: TaiwanCity?
    @State private var styleTags: [String] = []
    @State private var styleInput = ""
    @State private var budgetMin: Double = 500
    @State private var budgetMax: Double = 3000
    @State private var isSubmitting = false
    @State private var error: String?

    var onComplete: () -> Void

    private let api = APIClient.shared
    private let totalSteps = 4

    private let suggestedStyles = [
        "自然風", "日系", "韓系", "歐美", "時尚", "簡約",
        "可愛", "優雅", "個性", "清新"
    ]

    var body: some View {
        ZStack {
            BTColor.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                progressDots
                    .padding(.top, BTSpacing.xxl + 16)
                    .padding(.bottom, BTSpacing.xl)

                // Content
                TabView(selection: $currentStep) {
                    stepServicePreferences
                        .tag(0)
                    stepLocationPreferences
                        .tag(1)
                    stepStylePreferences
                        .tag(2)
                    stepBudgetRange
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                // Bottom button
                bottomButton
                    .padding(.horizontal, BTSpacing.xl)
                    .padding(.bottom, BTSpacing.xxl)
            }
        }
        .alert("Error", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: BTSpacing.sm) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? BTColor.primary : BTColor.primary.opacity(0.2))
                    .frame(width: index == currentStep ? 10 : 8, height: index == currentStep ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Service Preferences

    private var stepServicePreferences: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                stepHeader(
                    title: "服務偏好",
                    subtitle: "選擇您感興趣的美容服務類型"
                )

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: BTSpacing.md) {
                    ForEach(ServiceCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategories.contains(category)
                        ) {
                            toggleCategory(category)
                        }
                    }
                }
            }
            .padding(.horizontal, BTSpacing.xl)
        }
    }

    // MARK: - Step 2: Location Preferences

    private var stepLocationPreferences: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                stepHeader(
                    title: "地點偏好",
                    subtitle: "選擇您常去的城市"
                )

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: BTSpacing.md) {
                    ForEach(TaiwanCity.allCases, id: \.self) { city in
                        CityChip(
                            city: city,
                            isSelected: selectedCity == city
                        ) {
                            selectedCity = city
                        }
                    }
                }
            }
            .padding(.horizontal, BTSpacing.xl)
        }
    }

    // MARK: - Step 3: Style Preferences

    private var stepStylePreferences: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                stepHeader(
                    title: "風格偏好",
                    subtitle: "選擇或輸入您喜歡的風格"
                )

                // Suggested styles
                FlowLayout(spacing: BTSpacing.sm) {
                    ForEach(suggestedStyles, id: \.self) { style in
                        StyleTag(
                            text: style,
                            isSelected: styleTags.contains(style)
                        ) {
                            toggleStyle(style)
                        }
                    }
                }

                // Custom input
                HStack(spacing: BTSpacing.sm) {
                    TextField("自訂風格...", text: $styleInput)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, BTSpacing.md)
                        .padding(.vertical, BTSpacing.md)
                        .background(BTColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: BTRadius.sm)
                                .stroke(BTColor.border, lineWidth: 1)
                        )

                    Button {
                        addCustomStyle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(BTColor.primary)
                    }
                    .disabled(styleInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                // Selected tags
                if !styleTags.isEmpty {
                    VStack(alignment: .leading, spacing: BTSpacing.sm) {
                        Text("已選擇")
                            .font(.subheadline)
                            .foregroundStyle(BTColor.textSecondary)

                        FlowLayout(spacing: BTSpacing.sm) {
                            ForEach(styleTags, id: \.self) { tag in
                                HStack(spacing: BTSpacing.xs) {
                                    Text(tag)
                                        .font(.subheadline)
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, BTSpacing.md)
                                .padding(.vertical, BTSpacing.sm)
                                .background(BTColor.primary)
                                .clipShape(Capsule())
                                .onTapGesture {
                                    styleTags.removeAll { $0 == tag }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, BTSpacing.xl)
        }
    }

    // MARK: - Step 4: Budget Range

    private var stepBudgetRange: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xl) {
                stepHeader(
                    title: "預算範圍",
                    subtitle: "設定您每次消費的預算區間"
                )

                VStack(spacing: BTSpacing.xxl) {
                    // Budget display
                    HStack {
                        VStack(spacing: BTSpacing.xs) {
                            Text("最低")
                                .font(.caption)
                                .foregroundStyle(BTColor.textSecondary)
                            Text(Formatters.formatPrice(budgetMin))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(BTColor.primary)
                        }
                        .frame(maxWidth: .infinity)

                        Text("~")
                            .font(.title2)
                            .foregroundStyle(BTColor.textTertiary)

                        VStack(spacing: BTSpacing.xs) {
                            Text("最高")
                                .font(.caption)
                                .foregroundStyle(BTColor.textSecondary)
                            Text(Formatters.formatPrice(budgetMax))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(BTColor.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(BTSpacing.xl)
                    .btCard()

                    // Min slider
                    VStack(alignment: .leading, spacing: BTSpacing.sm) {
                        Text("最低預算")
                            .font(.subheadline)
                            .foregroundStyle(BTColor.textSecondary)
                        Slider(value: $budgetMin, in: 0...10000, step: 100) {
                            Text("最低預算")
                        }
                        .tint(BTColor.primary)
                        .onChange(of: budgetMin) { _, newValue in
                            if newValue > budgetMax {
                                budgetMax = newValue
                            }
                        }
                    }

                    // Max slider
                    VStack(alignment: .leading, spacing: BTSpacing.sm) {
                        Text("最高預算")
                            .font(.subheadline)
                            .foregroundStyle(BTColor.textSecondary)
                        Slider(value: $budgetMax, in: 0...10000, step: 100) {
                            Text("最高預算")
                        }
                        .tint(BTColor.primaryDark)
                        .onChange(of: budgetMax) { _, newValue in
                            if newValue < budgetMin {
                                budgetMin = newValue
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, BTSpacing.xl)
        }
    }

    // MARK: - Step Header

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: BTSpacing.sm) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(BTColor.textPrimary)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(BTColor.textSecondary)
        }
        .padding(.bottom, BTSpacing.sm)
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Button {
            if currentStep < totalSteps - 1 {
                withAnimation { currentStep += 1 }
            } else {
                Task { await submitSurvey() }
            }
        } label: {
            Group {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(currentStep < totalSteps - 1 ? "下一步" : "完成")
                }
            }
            .btPrimaryButton(isDisabled: !isCurrentStepValid)
        }
        .disabled(!isCurrentStepValid || isSubmitting)
    }

    // MARK: - Validation

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return !selectedCategories.isEmpty
        case 1: return selectedCity != nil
        case 2: return !styleTags.isEmpty
        case 3: return budgetMin <= budgetMax
        default: return true
        }
    }

    // MARK: - Actions

    private func toggleCategory(_ category: ServiceCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    private func toggleStyle(_ style: String) {
        if styleTags.contains(style) {
            styleTags.removeAll { $0 == style }
        } else {
            styleTags.append(style)
        }
    }

    private func addCustomStyle() {
        let trimmed = styleInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !styleTags.contains(trimmed) else { return }
        styleTags.append(trimmed)
        styleInput = ""
    }

    private func submitSurvey() async {
        isSubmitting = true
        do {
            let body = JSONBody([
                "preferredServices": selectedCategories.map(\.rawValue) as Any,
                "preferredCity": selectedCity?.rawValue as Any,
                "preferredStyles": styleTags as Any,
                "budgetMin": Int(budgetMin) as Any,
                "budgetMax": Int(budgetMax) as Any
            ])
            let _: UserPreference = try await api.post(
                path: APIEndpoints.Survey.preferences,
                body: body
            )
            await MainActor.run {
                onComplete()
            }
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let category: ServiceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: BTSpacing.sm) {
                Image(systemName: category.iconName)
                    .font(.title2)
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BTSpacing.lg)
            .foregroundStyle(isSelected ? .white : BTColor.textPrimary)
            .background(isSelected ? BTColor.primary : BTColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(isSelected ? BTColor.primary : BTColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - City Chip

private struct CityChip: View {
    let city: TaiwanCity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(city.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BTSpacing.md)
                .foregroundStyle(isSelected ? .white : BTColor.textPrimary)
                .background(isSelected ? BTColor.primary : BTColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.sm)
                        .stroke(isSelected ? BTColor.primary : BTColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Style Tag

private struct StyleTag: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, BTSpacing.lg)
                .padding(.vertical, BTSpacing.sm)
                .foregroundStyle(isSelected ? .white : BTColor.primary)
                .background(isSelected ? BTColor.primary : BTColor.secondaryBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

#Preview {
    SurveyView(onComplete: {})
        .environment(UserStore())
}
