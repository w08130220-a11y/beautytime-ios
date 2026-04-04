import SwiftUI

struct ProductManageView: View {
    @Environment(ProductStore.self) private var store
    @State private var showAddProduct = false
    @State private var editingProduct: Product?

    var body: some View {
        List {
            if store.products.isEmpty {
                ContentUnavailableView(
                    "尚無產品",
                    systemImage: "bag",
                    description: Text("新增產品開始追蹤銷售和抽成")
                )
            } else {
                ForEach(store.products) { product in
                    ProductRow(product: product)
                        .onTapGesture { editingProduct = product }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await store.deleteProduct(id: product.id) }
                            } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("產品管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddProduct = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await store.loadProducts() }
        .sheet(isPresented: $showAddProduct) {
            AddEditProductSheet(store: store, product: nil)
        }
        .sheet(item: $editingProduct) { product in
            AddEditProductSheet(store: store, product: product)
        }
    }
}

// MARK: - Product Row

private struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Text(Formatters.formatPrice(product.price))
                        .font(.caption)
                        .foregroundStyle(.accent)
                    if product.hasCommission == true, let rate = product.commissionRate {
                        Text("抽成 \(Int(rate * 100))%")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    if let stock = product.stock {
                        Text("庫存 \(stock)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if product.isActive == false {
                Text("停用")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Add/Edit Product Sheet

private struct AddEditProductSheet: View {
    let store: ProductStore
    let product: Product?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var price: String = ""
    @State private var cost: String = ""
    @State private var hasCommission: Bool = false
    @State private var commissionRate: String = ""
    @State private var stock: String = ""
    @State private var isActive: Bool = true

    var isEditing: Bool { product != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("產品資訊") {
                    TextField("產品名稱", text: $name)
                    TextField("售價", text: $price)
                        .keyboardType(.decimalPad)
                    TextField("成本（選填）", text: $cost)
                        .keyboardType(.decimalPad)
                    TextField("庫存數量（選填）", text: $stock)
                        .keyboardType(.numberPad)
                }

                Section("銷售抽成") {
                    Toggle("啟用銷售抽成", isOn: $hasCommission)
                    if hasCommission {
                        HStack {
                            Text("抽成比例")
                            Spacer()
                            TextField("", text: $commissionRate)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                                .multilineTextAlignment(.trailing)
                            Text("%")
                        }
                    }
                }

                Section {
                    Toggle("上架中", isOn: $isActive)
                }
            }
            .navigationTitle(isEditing ? "編輯產品" : "新增產品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(name.isEmpty || price.isEmpty)
                }
            }
            .onAppear {
                if let p = product {
                    name = p.name
                    price = "\(p.price)"
                    cost = p.cost.map { "\($0)" } ?? ""
                    hasCommission = p.hasCommission ?? false
                    commissionRate = p.commissionRate.map { "\(Int($0 * 100))" } ?? ""
                    stock = p.stock.map { "\($0)" } ?? ""
                    isActive = p.isActive ?? true
                }
            }
        }
    }

    private func save() {
        var body: [String: Any] = [
            "providerId": store.providerId,
            "name": name,
            "price": Double(price) ?? 0,
            "hasCommission": hasCommission,
            "isActive": isActive
        ]
        if let costVal = Double(cost) { body["cost"] = costVal }
        if hasCommission, let rate = Double(commissionRate) {
            body["commissionRate"] = rate / 100.0
        }
        if let stockVal = Int(stock) { body["stock"] = stockVal }

        Task {
            if let p = product {
                await store.updateProduct(id: p.id, body: body)
            } else {
                await store.createProduct(body)
            }
            dismiss()
        }
    }
}
