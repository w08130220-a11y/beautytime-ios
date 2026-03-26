import SwiftUI
import Kingfisher
import PhotosUI

struct EditProfileView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var phone = ""
    @State private var preferredLocale: AppLocale = .zhTW
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?

    @State private var isSaving = false
    @State private var error: String?
    @State private var showError = false

    private let api = APIClient.shared

    var body: some View {
        Form {
            // MARK: - Avatar
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        if let avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else if let avatarUrl = authStore.currentUser?.avatarUrl,
                                  let url = URL(string: avatarUrl) {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("更換頭像")
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // MARK: - Info Fields
            Section(header: Text("基本資料")) {
                HStack {
                    Text("姓名")
                        .frame(width: 80, alignment: .leading)
                    TextField("輸入姓名", text: $fullName)
                        .textContentType(.name)
                }

                HStack {
                    Text("Email")
                        .frame(width: 80, alignment: .leading)
                    Text(authStore.currentUser?.email ?? "")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("電話")
                        .frame(width: 80, alignment: .leading)
                    TextField("輸入電話", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
            }

            // MARK: - Locale
            Section(header: Text("偏好語言")) {
                Picker("語言", selection: $preferredLocale) {
                    Text("繁體中文").tag(AppLocale.zhTW)
                    Text("English").tag(AppLocale.en)
                }
                .pickerStyle(.segmented)
            }

            // MARK: - Save
            Section {
                Button {
                    Task { await saveProfile() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("儲存")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("編輯個人資料")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCurrentValues() }
        .onChange(of: selectedPhoto) { _, newItem in
            Task { await loadSelectedPhoto(newItem) }
        }
        .alert("儲存失敗", isPresented: $showError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(error ?? "請稍後再試")
        }
    }

    // MARK: - Private

    private func loadCurrentValues() {
        guard let user = authStore.currentUser else { return }
        fullName = user.fullName ?? ""
        phone = user.phone ?? ""
        preferredLocale = user.preferredLocale ?? .zhTW
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            avatarImage = Image(uiImage: uiImage)
        }
    }

    private func saveProfile() async {
        isSaving = true
        error = nil
        do {
            // Upload avatar if selected
            if let selectedPhoto {
                if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
                    let base64 = data.base64EncodedString()
                    let uploadBody: [String: Any] = [
                        "fileName": "avatar.jpg",
                        "contentType": "image/jpeg",
                        "fileData": base64
                    ]
                    let _: User = try await api.post(
                        path: APIEndpoints.Users.avatar,
                        body: JSONBody(uploadBody)
                    )
                }
            }

            let body: [String: String] = [
                "fullName": fullName,
                "phone": phone,
                "preferredLocale": preferredLocale.rawValue
            ]
            let _: User = try await api.patch(
                path: APIEndpoints.Auth.me,
                body: body
            )
            await authStore.fetchCurrentUser()
            dismiss()
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environment(AuthStore())
    }
}
