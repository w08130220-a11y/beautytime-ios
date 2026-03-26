import SwiftUI

struct ServicesManageView: View {
    @Environment(ManageStore.self) private var store

    @State private var showAddSheet = false
    @State private var editingService: Service?

    var body: some View {
        List {
            ForEach(store.services) { service in
                ServiceRow(service: service)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingService = service
                    }
            }
            .onDelete(perform: deleteServices)
        }
        .navigationTitle("服務管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("新增服務", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ServiceFormSheet(store: store, service: nil)
        }
        .sheet(item: $editingService) { service in
            ServiceFormSheet(store: store, service: service)
        }
        .task {
            await store.loadServices()
        }
    }

    private func deleteServices(at offsets: IndexSet) {
        for index in offsets {
            let service = store.services[index]
            Task {
                await store.deleteService(id: service.id)
            }
        }
    }
}

// MARK: - Service Row

private struct ServiceRow: View {
    let service: Service

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)
                HStack(spacing: 12) {
                    if let duration = service.duration {
                        Label("\(duration) 分鐘", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let price = service.price {
                        Label(Formatters.formatPrice(price), systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Circle()
                .fill(service.isAvailable == true ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Service Form Sheet

private struct ServiceFormSheet: View {
    let store: ManageStore
    let service: Service?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var category: ServiceCategory = .nailLash
    @State private var durationMinutes: Int = 60
    @State private var price: String = ""
    @State private var isAvailable: Bool = true

    private let durationOptions = stride(from: 15, through: 300, by: 15).map { $0 }

    private var isEditing: Bool { service != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("服務名稱", text: $name)
                    TextField("描述", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("分類", selection: $category) {
                        ForEach(ServiceCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                Section("時間與價格") {
                    Picker("時長", selection: $durationMinutes) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text("\(minutes) 分鐘").tag(minutes)
                        }
                    }
                    TextField("價格 (NT$)", text: $price)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle("上架中", isOn: $isAvailable)
                }
            }
            .navigationTitle(isEditing ? "編輯服務" : "新增服務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        Task {
                            await save()
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let service {
                    name = service.name
                    description = service.description ?? ""
                    if let cat = service.category, let parsed = ServiceCategory(rawValue: cat) {
                        category = parsed
                    }
                    durationMinutes = service.duration ?? 60
                    price = service.price.map { "\(Int($0))" } ?? ""
                    isAvailable = service.isAvailable ?? true
                }
            }
        }
    }

    private func save() async {
        let body: [String: Any] = [
            "providerId": store.providerId,
            "name": name,
            "description": description,
            "category": category.rawValue,
            "duration": durationMinutes,
            "price": Double(price) ?? 0,
            "isAvailable": isAvailable
        ]

        if let service {
            await store.updateService(id: service.id, body: body)
        } else {
            await store.createService(body)
        }
    }
}

#Preview {
    NavigationStack {
        ServicesManageView()
            .environment(ManageStore())
    }
}
