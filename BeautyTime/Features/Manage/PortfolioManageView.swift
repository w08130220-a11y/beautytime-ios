import SwiftUI
import Kingfisher
import PhotosUI

struct PortfolioManageView: View {
    @Environment(ManageStore.self) private var store

    @State private var showAddSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if store.portfolio.isEmpty {
                ContentUnavailableView(
                    "尚無作品",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("點擊右上角新增作品")
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.portfolio) { item in
                        PortfolioCard(item: item, onDelete: {
                            Task { await store.deletePortfolioItem(id: item.id) }
                        })
                    }
                }
                .padding()
            }
        }
        .navigationTitle("作品集管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("新增作品", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPortfolioSheet(store: store)
        }
        .task {
            await store.loadPortfolio()
        }
    }
}

// MARK: - Portfolio Card

private struct PortfolioCard: View {
    let item: PortfolioItem
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    // Before photo
                    if let beforeUrl = item.beforePhotoUrl, let url = URL(string: beforeUrl) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 80)
                            .clipped()
                            .overlay(alignment: .bottomLeading) {
                                Text("Before")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(.black.opacity(0.6))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(4)
                            }
                    }

                    // After photo
                    if let afterUrl = item.afterPhotoUrl, let url = URL(string: afterUrl) {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 80)
                            .clipped()
                            .overlay(alignment: .bottomLeading) {
                                Text("After")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(.black.opacity(0.6))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .padding(4)
                            }
                    }
                }

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .red)
                }
                .padding(6)
            }

            // Style tags
            if let tags = item.styleTags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            if let desc = item.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.bottom, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add Portfolio Sheet

private struct AddPortfolioSheet: View {
    let store: ManageStore

    @Environment(\.dismiss) private var dismiss

    @State private var selectedBeforeItem: PhotosPickerItem?
    @State private var selectedAfterItem: PhotosPickerItem?
    @State private var beforeImageData: Data?
    @State private var afterImageData: Data?
    @State private var description: String = ""
    @State private var styleTagsText: String = ""
    @State private var isUploading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Before 照片") {
                    if let beforeImageData, let uiImage = UIImage(data: beforeImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    PhotosPicker(selection: $selectedBeforeItem, matching: .images) {
                        Label(beforeImageData == nil ? "選擇照片" : "更換照片", systemImage: "photo")
                    }
                    .onChange(of: selectedBeforeItem) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                beforeImageData = data
                            }
                        }
                    }
                }

                Section("After 照片") {
                    if let afterImageData, let uiImage = UIImage(data: afterImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    PhotosPicker(selection: $selectedAfterItem, matching: .images) {
                        Label(afterImageData == nil ? "選擇照片" : "更換照片", systemImage: "photo")
                    }
                    .onChange(of: selectedAfterItem) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                afterImageData = data
                            }
                        }
                    }
                }

                Section("描述") {
                    TextField("作品描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("風格標籤（以逗號分隔）") {
                    TextField("例如：日系, 韓系, 自然", text: $styleTagsText)
                }

                if isUploading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("上傳中...")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("新增作品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isUploading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("上傳") {
                        Task { await uploadPortfolio() }
                    }
                    .disabled(isUploading || (beforeImageData == nil && afterImageData == nil))
                }
            }
        }
    }

    private func uploadPortfolio() async {
        isUploading = true

        // Upload before image
        var beforeUrl: String?
        if let beforeImageData {
            let base64 = beforeImageData.base64EncodedString()
            beforeUrl = await store.uploadPortfolioImage(
                fileName: "before.jpg",
                contentType: "image/jpeg",
                fileData: base64
            )
        }

        // Upload after image
        var afterUrl: String?
        if let afterImageData {
            let base64 = afterImageData.base64EncodedString()
            afterUrl = await store.uploadPortfolioImage(
                fileName: "after.jpg",
                contentType: "image/jpeg",
                fileData: base64
            )
        }

        // Parse style tags
        let tags = styleTagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Create portfolio item
        await store.createPortfolioItem(
            beforeUrl: beforeUrl,
            afterUrl: afterUrl,
            description: description.isEmpty ? nil : description,
            styleTags: tags.isEmpty ? nil : tags
        )

        isUploading = false
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PortfolioManageView()
            .environment(ManageStore())
    }
}
