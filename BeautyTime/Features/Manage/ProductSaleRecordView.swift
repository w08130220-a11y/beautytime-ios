import SwiftUI

/// Record a product sale: select staff, product, quantity.
struct ProductSaleRecordView: View {
    @Environment(ProductStore.self) private var productStore
    @Environment(StaffManageStore.self) private var staffStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStaffId: String?
    @State private var selectedProductId: String?
    @State private var quantity: Int = 1

    private var selectedProduct: Product? {
        productStore.products.first { $0.id == selectedProductId }
    }

    private var totalAmount: Double {
        (selectedProduct?.price ?? 0) * Double(quantity)
    }

    private var commissionAmount: Double {
        guard let product = selectedProduct, product.hasCommission == true else { return 0 }
        return totalAmount * (product.commissionRate ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Staff picker
                Section("銷售人員") {
                    Picker("選擇設計師", selection: $selectedStaffId) {
                        Text("請選擇").tag(nil as String?)
                        ForEach(staffStore.staff) { staff in
                            Text(staff.name).tag(staff.id as String?)
                        }
                    }
                }

                // Product picker
                Section("產品") {
                    Picker("選擇產品", selection: $selectedProductId) {
                        Text("請選擇").tag(nil as String?)
                        ForEach(productStore.products.filter { $0.isActive != false }) { product in
                            HStack {
                                Text(product.name)
                                Spacer()
                                Text(Formatters.formatPrice(product.price))
                            }
                            .tag(product.id as String?)
                        }
                    }

                    Stepper("數量：\(quantity)", value: $quantity, in: 1...99)
                }

                // Summary
                if selectedProduct != nil {
                    Section("摘要") {
                        HStack {
                            Text("小計")
                            Spacer()
                            Text(Formatters.formatPrice(totalAmount))
                                .fontWeight(.medium)
                        }
                        if commissionAmount > 0 {
                            HStack {
                                Text("設計師抽成")
                                Spacer()
                                Text(Formatters.formatPrice(commissionAmount))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("記錄產品銷售")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認") {
                        guard let staffId = selectedStaffId,
                              let productId = selectedProductId else { return }
                        Task {
                            await productStore.recordSale(
                                staffId: staffId,
                                productId: productId,
                                quantity: quantity,
                                customerId: nil,
                                bookingId: nil
                            )
                            dismiss()
                        }
                    }
                    .disabled(selectedStaffId == nil || selectedProductId == nil)
                }
            }
        }
    }
}
