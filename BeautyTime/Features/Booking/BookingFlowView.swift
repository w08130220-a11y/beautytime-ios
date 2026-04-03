import SwiftUI

struct BookingFlowView: View {
    let providerId: String
    @State private var store = BookingFlowStore()
    @State private var showSuccess = false
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Step Indicator
            stepIndicator
                .padding(.vertical, 16)

            // Step Title
            Text(store.currentStep.title)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)

            Divider()

            // MARK: - Content
            ScrollView {
                contentView
                    .padding()
            }

            Divider()

            // MARK: - Navigation Buttons
            navigationButtons
                .padding()
        }
        .navigationTitle("預約")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
        }
        .alert("錯誤", isPresented: .init(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("確定", role: .cancel) { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
        .onAppear {
            store.providerId = providerId
        }
        .task {
            await store.loadServices()
        }
        .alert("預約成功", isPresented: $showSuccess) {
            Button("查看我的預約") {
                NotificationCenter.default.post(name: .switchToMyBookings, object: nil)
                dismiss()
            }
        } message: {
            Text("您的預約已建立，可在「我的預約」中查看。")
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 12) {
            ForEach(BookingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step == store.currentStep ? Color.accentColor : (step.rawValue < store.currentStep.rawValue ? Color.accentColor.opacity(0.5) : Color(.systemGray4)))
                    .frame(width: 12, height: 12)
                    .overlay {
                        if step.rawValue < store.currentStep.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                if step != BookingStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < store.currentStep.rawValue ? Color.accentColor.opacity(0.5) : Color(.systemGray4))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch store.currentStep {
        case .selectService:
            SelectServiceStep(store: store)
        case .selectDate:
            SelectDateStep(store: store)
        case .selectStaffTime:
            SelectStaffTimeStep(store: store)
        case .confirm:
            ConfirmStep(store: store)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if store.currentStep != .selectService {
                Button {
                    store.previousStep()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("上一步")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }

            if store.currentStep == .confirm {
                Button {
                    guard !isSubmitting else { return }
                    isSubmitting = true
                    Task {
                        await store.createBooking()
                        if store.createdBooking != nil {
                            showSuccess = true
                        }
                        isSubmitting = false
                    }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("確認預約")
                        Image(systemName: "checkmark.circle")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed || isSubmitting)
            } else {
                Button {
                    store.nextStep()
                } label: {
                    HStack {
                        Text("下一步")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
        }
    }

    private var canProceed: Bool {
        switch store.currentStep {
        case .selectService:
            return store.selectedService != nil
        case .selectDate:
            return store.selectedDate != nil
        case .selectStaffTime:
            return store.selectedTime != nil
        case .confirm:
            return !store.isLoading
        }
    }
}

#Preview {
    NavigationStack {
        BookingFlowView(providerId: "preview-provider")
    }
}
