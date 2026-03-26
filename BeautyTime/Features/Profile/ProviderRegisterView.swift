import SwiftUI

struct ProviderRegisterView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ServiceCategory = .nail
    @State private var description = ""
    @State private var phone = ""
    @State private var city: TaiwanCity = .taipei
    @State private var district = ""
    @State private var address = ""
    @State private var depositRate = "0.3"

    @State private var isSubmitting = false
    @State private var error: String?
    @State private var showSuccess = false

    private let api = APIClient.shared

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section(header: Text("基本資訊")) {
                TextField("商家名稱 *", text: $name)

                Picker("服務類別", selection: $category) {
                    ForEach(ServiceCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }

                TextField("聯絡電話 *", text: $phone)
                    .keyboardType(.phonePad)
            }

            Section(header: Text("商家介紹")) {
                TextEditor(text: $description)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("描述您的服務特色...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            }

            Section(header: Text("地址")) {
                Picker("城市", selection: $city) {
                    ForEach(TaiwanCity.allCases, id: \.self) { c in
                        Text(c.displayName).tag(c)
                    }
                }

                TextField("區域", text: $district)

                TextField("詳細地址 *", text: $address)
            }

            Section(header: Text("訂金比例"), footer: Text("顧客預約時需先支付的訂金比例（0.1 = 10%）")) {
                TextField("訂金比例", text: $depositRate)
                    .keyboardType(.decimalPad)
            }

            Section {
                Button {
                    Task { await submitRegistration() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("提交申請")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!isFormValid || isSubmitting)
                .listRowBackground(isFormValid && !isSubmitting ? Color.pink : Color.pink.opacity(0.4))
                .foregroundStyle(.white)
            }

            if let error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("申請成為服務商")
        .navigationBarTitleDisplayMode(.inline)
        .alert("申請已提交", isPresented: $showSuccess) {
            Button("確定") {
                Task {
                    await authStore.fetchCurrentUser()
                }
                dismiss()
            }
        } message: {
            Text("您的服務商申請已提交，審核通過後即可開始使用管理功能。")
        }
    }

    private func submitRegistration() async {
        isSubmitting = true
        error = nil

        do {
            let body: [String: Any] = [
                "name": name.trimmingCharacters(in: .whitespaces),
                "category": category.rawValue,
                "description": description,
                "phone": phone.trimmingCharacters(in: .whitespaces),
                "city": city.rawValue,
                "district": district,
                "address": address.trimmingCharacters(in: .whitespaces),
                "depositRate": Double(depositRate) ?? 0.3
            ]

            let _: Provider = try await api.post(
                path: "/api/providers/register",
                body: JSONBody(body)
            )
            showSuccess = true
        } catch let apiError as APIError {
            switch apiError {
            case .httpError(let statusCode, _):
                if statusCode == 409 {
                    error = "您已經有一個服務商帳號了"
                } else {
                    error = "提交失敗（錯誤碼：\(statusCode)）"
                }
            default:
                error = apiError.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }

        isSubmitting = false
    }
}
