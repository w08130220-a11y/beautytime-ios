import SwiftUI
import PhotosUI

struct CreateMatchView: View {
    @Environment(\.dismiss) private var dismiss

    // Form fields
    @State private var serviceType: ServiceCategory = .nail
    @State private var preferredDate: Date = .now
    @State private var preferredTime: Date = .now
    @State private var city: TaiwanCity = .taipei
    @State private var district: String = ""
    @State private var budgetMinText: String = ""
    @State private var budgetMaxText: String = ""
    @State private var note: String = ""
    @State private var selectedPhoto: PhotosPickerItem?

    // State
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var showError = false

    private let api = APIClient.shared
    var onCreated: (() async -> Void)?

    var body: some View {
        Form {
            serviceSection
            dateTimeSection
            locationSection
            budgetSection
            noteSection
            photoSection
        }
        .navigationTitle("建立需求")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("送出需求") {
                    Task { await submitRequest() }
                }
                .disabled(isSubmitting)
            }
        }
        .disabled(isSubmitting)
        .overlay {
            if isSubmitting {
                ProgressView("送出中...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("錯誤", isPresented: $showError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(error ?? "未知錯誤")
        }
    }

    // MARK: - Sections

    private var serviceSection: some View {
        Section("服務類型") {
            Picker("類型", selection: $serviceType) {
                ForEach(ServiceCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.iconName)
                        .tag(category)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var dateTimeSection: some View {
        Section("偏好時間") {
            DatePicker(
                "日期",
                selection: $preferredDate,
                in: Date()...,
                displayedComponents: .date
            )
            DatePicker(
                "時間",
                selection: $preferredTime,
                displayedComponents: .hourAndMinute
            )
        }
    }

    private var locationSection: some View {
        Section("地點") {
            Picker("縣市", selection: $city) {
                ForEach(TaiwanCity.allCases, id: \.self) { city in
                    Text(city.displayName).tag(city)
                }
            }
            .pickerStyle(.menu)
            TextField("區域（如：大安區）", text: $district)
        }
    }

    private var budgetSection: some View {
        Section("預算範圍") {
            HStack {
                TextField("最低", text: $budgetMinText)
                    .keyboardType(.numberPad)
                Text("–")
                    .foregroundStyle(.secondary)
                TextField("最高", text: $budgetMaxText)
                    .keyboardType(.numberPad)
            }
        }
    }

    private var noteSection: some View {
        Section("備註") {
            TextEditor(text: $note)
                .frame(minHeight: 80)
        }
    }

    private var photoSection: some View {
        Section("參考照片") {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images
            ) {
                Label("選擇照片", systemImage: "photo.on.rectangle")
            }
            if selectedPhoto != nil {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("已選擇照片")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Submit

    private func submitRequest() async {
        isSubmitting = true
        error = nil

        let body = CreateMatchRequestBody(
            serviceType: serviceType.rawValue,
            preferredDate: Formatters.dateFormatter.string(from: preferredDate),
            preferredTime: Formatters.timeFormatter.string(from: preferredTime),
            city: city.displayName,
            district: district.isEmpty ? nil : district,
            budgetMin: Double(budgetMinText),
            budgetMax: Double(budgetMaxText),
            note: note.isEmpty ? nil : note
        )

        do {
            let _: MatchRequest = try await api.post(
                path: APIEndpoints.Match.createRequest,
                body: body
            )
            await onCreated?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}

// MARK: - Request Body

private struct CreateMatchRequestBody: Encodable {
    let serviceType: String
    let preferredDate: String
    let preferredTime: String
    let city: String
    let district: String?
    let budgetMin: Double?
    let budgetMax: Double?
    let note: String?
}

#Preview {
    NavigationStack {
        CreateMatchView()
    }
}
