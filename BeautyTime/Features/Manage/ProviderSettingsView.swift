import SwiftUI
import PhotosUI

struct ProviderSettingsView: View {
    @Environment(ManageStore.self) private var store

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var category: ServiceCategory = .nailLash
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var district: String = ""
    @State private var phone: String = ""
    @State private var depositRate: String = "30"
    @State private var instagramUrl: String = ""
    @State private var reviewNote: String = ""

    @State private var isSaving = false
    @State private var showSavedAlert = false
    @State private var isLoaded = false

    @State private var selectedCoverPhoto: PhotosPickerItem?
    @State private var coverImageData: Data?

    var body: some View {
        Form {
            Section("封面照片") {
                if let coverImageData, let uiImage = UIImage(data: coverImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                PhotosPicker(selection: $selectedCoverPhoto, matching: .images) {
                    Label(coverImageData == nil ? "選擇封面照片" : "更換封面照片", systemImage: "photo")
                }
                .onChange(of: selectedCoverPhoto) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            coverImageData = data
                        }
                    }
                }
            }

            Section("店家資訊") {
                TextField("店家名稱", text: $name)
                TextField("描述", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                Picker("分類", selection: $category) {
                    ForEach(ServiceCategory.allCases, id: \.self) { cat in
                        Text(cat.displayName).tag(cat)
                    }
                }
            }

            Section("地址") {
                TextField("地址", text: $address)
                TextField("城市", text: $city)
                TextField("區域", text: $district)
            }

            Section("聯絡方式") {
                TextField("電話", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Instagram 網址", text: $instagramUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }

            Section("商業設定") {
                HStack {
                    Text("訂金比例 (%)")
                    Spacer()
                    TextField("", text: $depositRate)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
            }

            Section("評價提醒文字") {
                TextField("完成服務後顯示的文字", text: $reviewNote, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("儲存")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(isSaving || name.isEmpty)
            }

            Section("驗證狀態") {
                HStack {
                    Text("商業認證")
                    Spacer()
                    Label("未驗證", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("店家設定")
        .alert("已儲存", isPresented: $showSavedAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text("店家設定已更新")
        }
        .task {
            guard !isLoaded else { return }
            await loadProvider()
            isLoaded = true
        }
    }

    private func loadProvider() async {
        do {
            let provider: Provider = try await APIClient.shared.get(
                path: APIEndpoints.Providers.detail(store.providerId)
            )
            name = provider.name
            description = provider.description ?? ""
            category = provider.category ?? .nailLash
            address = provider.address ?? ""
            city = provider.city ?? ""
            district = provider.district ?? ""
            phone = provider.phone ?? ""
            depositRate = provider.depositRate.map { "\(Int($0 * 100))" } ?? "30"
            instagramUrl = provider.instagramUrl ?? ""
            reviewNote = provider.reviewNote ?? ""
        } catch {
            store.error = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        do {
            // Upload cover image if selected
            var coverUrl: String?
            if let coverImageData {
                let base64 = coverImageData.base64EncodedString()
                coverUrl = await store.uploadProviderImage(
                    fileName: "cover.jpg",
                    contentType: "image/jpeg",
                    fileData: base64
                )
            }

            var body: [String: Any] = [
                "name": name,
                "description": description,
                "category": category.rawValue,
                "address": address,
                "city": city,
                "district": district,
                "phone": phone,
                "depositRate": (Double(depositRate) ?? 30) / 100.0,
                "instagramUrl": instagramUrl,
                "reviewNote": reviewNote
            ]
            if let coverUrl {
                body["coverImageUrl"] = coverUrl
            }
            let _: Provider = try await APIClient.shared.patch(
                path: APIEndpoints.Providers.update(store.providerId),
                body: JSONBody(body)
            )
            showSavedAlert = true
        } catch {
            store.error = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        ProviderSettingsView()
            .environment(ManageStore())
    }
}
