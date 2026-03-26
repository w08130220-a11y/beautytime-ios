import SwiftUI

struct VoucherPlansView: View {
    @Environment(VoucherManageStore.self) private var store

    @State private var selectedTab: VoucherTab = .redeem
    @State private var showAddSheet = false

    enum VoucherTab: String, CaseIterable {
        case redeem = "核銷"
        case plans = "方案管理"
        case sold = "已售套券"
        case liability = "負債管理"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker
            Picker("票券功能", selection: $selectedTab) {
                ForEach(VoucherTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.md)

            // Tab content
            switch selectedTab {
            case .redeem:
                VoucherRedeemView()
                    .environment(store)
            case .plans:
                plansTab
            case .sold:
                soldTab
            case .liability:
                liabilityTab
            }
        }
        .navigationTitle("票券方案")
        .toolbar {
            if selectedTab == .plans {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("新增方案", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            VoucherPlanFormSheet(store: store)
        }
        .task {
            await store.loadVoucherPlans()
        }
    }

    // MARK: - Plans Tab

    private var plansTab: some View {
        List {
            if store.voucherPlans.isEmpty {
                ContentUnavailableView(
                    "尚無方案",
                    systemImage: "ticket",
                    description: Text("點擊右上角新增方案")
                )
            } else {
                ForEach(store.voucherPlans) { plan in
                    VoucherPlanRow(plan: plan)
                }
                .onDelete(perform: deletePlans)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Sold Tab

    private var soldTab: some View {
        List {
            if store.soldVouchers.isEmpty {
                ContentUnavailableView(
                    "尚無已售套券",
                    systemImage: "ticket",
                    description: Text("售出的套券將顯示在此")
                )
            } else {
                ForEach(store.soldVouchers) { voucher in
                    SoldVoucherRow(voucher: voucher)
                }
            }
        }
        .listStyle(.plain)
        .task {
            await store.loadSoldVouchers()
        }
        .refreshable {
            await store.loadSoldVouchers()
        }
    }

    // MARK: - Liability Tab

    private var liabilityTab: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                if let liability = store.voucherLiability {
                    VStack(alignment: .leading, spacing: BTSpacing.md) {
                        Text("負債概覽")
                            .font(.headline)
                            .foregroundStyle(BTColor.textPrimary)

                        HStack(spacing: BTSpacing.md) {
                            BTStatCard(
                                value: Formatters.formatPrice(liability.totalLiability ?? 0),
                                label: "總負債金額"
                            )
                            BTStatCard(
                                value: "\(liability.planCount ?? 0)",
                                label: "方案數"
                            )
                        }

                        HStack(spacing: BTSpacing.md) {
                            BTStatCard(
                                value: "\(liability.totalSessions ?? 0)",
                                label: "未核銷次數"
                            )
                            BTStatCard(
                                value: Formatters.formatPrice(liability.totalBalance ?? 0),
                                label: "未核銷餘額"
                            )
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "尚無負債資料",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("售出套券後將自動計算負債")
                    )
                }
            }
            .padding(BTSpacing.lg)
        }
        .btPageBackground()
        .task {
            await store.loadVoucherLiability()
        }
        .refreshable {
            await store.loadVoucherLiability()
        }
    }

    private func deletePlans(at offsets: IndexSet) {
        for index in offsets {
            let plan = store.voucherPlans[index]
            Task {
                await store.deleteVoucherPlan(id: plan.id)
            }
        }
    }
}

// MARK: - Voucher Plan Row

private struct VoucherPlanRow: View {
    let plan: VoucherPlan

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(plan.name)
                        .font(.headline)
                    if let type = plan.type {
                        BTBadge(text: type.displayName, color: type.color)
                    }
                }

                HStack(spacing: 12) {
                    if let price = plan.sellingPrice {
                        Text(Formatters.formatPrice(price))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text("已售 \(plan.soldCount ?? 0)")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }
            }

            Spacer()

            Circle()
                .fill(plan.isActive == true ? BTColor.success : BTColor.textTertiary)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sold Voucher Row

private struct SoldVoucherRow: View {
    let voucher: CustomerVoucher

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.locale = Locale(identifier: "zh-TW")
        return f
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(voucher.plan?.name ?? "票券")
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    if let status = voucher.status {
                        BTBadge(text: status.displayName, color: status.color)
                    }
                    if let expiry = voucher.expiresAt {
                        Text("到期: \(dateFormatter.string(from: expiry))")
                            .font(.caption)
                            .foregroundStyle(BTColor.textSecondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let sessions = voucher.sessionsRemaining {
                    Text("剩餘 \(sessions) 次")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }
                if let balance = voucher.balanceRemaining {
                    Text("餘額 \(Formatters.formatPrice(balance))")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Voucher Plan Form Sheet

private struct VoucherPlanFormSheet: View {
    let store: VoucherManageStore

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var type: VoucherType = .session
    @State private var description: String = ""
    @State private var originalPrice: String = ""
    @State private var sellingPrice: String = ""
    @State private var validDays: String = "90"
    @State private var sessionsTotal: String = "10"
    @State private var bonusAmount: String = ""
    @State private var maxSales: String = ""
    @State private var isActive: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("方案名稱", text: $name)
                    Picker("類型", selection: $type) {
                        Text("次數券").tag(VoucherType.session)
                        Text("儲值券").tag(VoucherType.storedValue)
                        Text("套裝券").tag(VoucherType.package)
                    }
                    TextField("描述", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("價格") {
                    TextField("原價 (NT$)", text: $originalPrice)
                        .keyboardType(.numberPad)
                    TextField("售價 (NT$)", text: $sellingPrice)
                        .keyboardType(.numberPad)
                }

                Section("方案設定") {
                    TextField("有效天數", text: $validDays)
                        .keyboardType(.numberPad)

                    if type == .session {
                        TextField("總次數", text: $sessionsTotal)
                            .keyboardType(.numberPad)
                    }

                    if type == .storedValue {
                        TextField("加贈金額 (NT$)", text: $bonusAmount)
                            .keyboardType(.numberPad)
                    }

                    TextField("限量（留空為不限）", text: $maxSales)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle("上架中", isOn: $isActive)
                }
            }
            .navigationTitle("新增方案")
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
                    .disabled(name.isEmpty || sellingPrice.isEmpty)
                }
            }
        }
    }

    private func save() async {
        var body: [String: Any] = [
            "providerId": store.providerId,
            "name": name,
            "type": type.rawValue,
            "description": description,
            "originalPrice": Double(originalPrice) ?? 0,
            "sellingPrice": Double(sellingPrice) ?? 0,
            "validDays": Int(validDays) ?? 90,
            "isActive": isActive
        ]

        if type == .session {
            body["sessionsTotal"] = Int(sessionsTotal) ?? 10
        }
        if type == .storedValue {
            body["bonusAmount"] = Double(bonusAmount) ?? 0
        }
        if let max = Int(maxSales), max > 0 {
            body["maxSales"] = max
        }

        await store.createVoucherPlan(body)
    }
}

#Preview {
    NavigationStack {
        VoucherPlansView()
            .environment(VoucherManageStore())
    }
}
