import SwiftUI

struct PayrollView: View {
    @Environment(PayrollManageStore.self) private var store
    @Environment(StaffManageStore.self) private var staffStore

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(Array(["抽成設定", "員工薪資", "月結算", "匯出"].enumerated()), id: \.offset) { index, title in
                    Button {
                        withAnimation { selectedTab = index }
                    } label: {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == index ? Color(.systemBackground) : Color(.systemGray6))
                            .foregroundStyle(selectedTab == index ? BTColor.textPrimary : BTColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
            .padding(.horizontal, BTSpacing.lg)
            .padding(.top, BTSpacing.sm)

            // Tab Content
            TabView(selection: $selectedTab) {
                CommissionSettingsTab(store: store).tag(0)
                StaffSalaryTab(store: store, staffStore: staffStore).tag(1)
                MonthlySettlementTab(store: store).tag(2)
                ExportTab(store: store).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("薪資管理")
        .task {
            async let commissionTask: () = store.loadCommissionSettings()
            async let salaryTask: () = store.loadSalaryConfigs()
            async let staffTask: () = staffStore.loadStaff()
            _ = await (commissionTask, salaryTask, staffTask)
            await store.loadCommissionTiers()
        }
        .alert("錯誤", isPresented: Binding(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("確定") { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
    }
}

// MARK: - Tab 1: Commission Settings

private struct CommissionSettingsTab: View {
    let store: PayrollManageStore
    @State private var showAddTier = false

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                // Tiered Commission Section
                VStack(alignment: .leading, spacing: BTSpacing.md) {
                    Text("階梯式抽成")
                        .font(.headline)
                    Text("依員工個人月營業額分段計算抽成比例。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if store.commissionTiers.isEmpty {
                        Text("尚無階梯設定")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(store.commissionTiers) { tier in
                            CommissionTierRow(tier: tier, store: store)
                        }
                    }

                    Button {
                        showAddTier = true
                    } label: {
                        Label("新增階梯", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.small)
                }
                .padding(BTSpacing.lg)
                .btCard()

                // Product Commission
                if let settings = store.commissionSettings {
                    VStack(alignment: .leading, spacing: BTSpacing.sm) {
                        Text("產品抽成")
                            .font(.headline)
                        Text("\(Int((settings.productCommissionRate ?? 0) * 100))%")
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(BTSpacing.lg)
                    .btCard()
                }
            }
            .padding(BTSpacing.lg)
        }
        .sheet(isPresented: $showAddTier) {
            AddCommissionTierSheet(store: store)
        }
    }
}

private struct CommissionTierRow: View {
    let tier: CommissionTier
    let store: PayrollManageStore
    @State private var showEdit = false

    var body: some View {
        HStack {
            Text("\(Formatters.formatPrice(tier.minRevenue ?? 0)) ~ \(tier.maxRevenue != nil ? Formatters.formatPrice(tier.maxRevenue!) : "無上限")")
                .font(.subheadline)

            Spacer()

            Text("\(Int((tier.rate ?? 0) * 100))%")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(BTColor.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(BTColor.primary.opacity(0.1))
                .clipShape(Capsule())

            Button { showEdit = true } label: {
                Image(systemName: "pencil.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button {
                Task { await store.deleteCommissionTier(id: tier.id) }
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(BTSpacing.md)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
        .sheet(isPresented: $showEdit) {
            EditCommissionTierSheet(store: store, tier: tier)
        }
    }
}

private struct AddCommissionTierSheet: View {
    let store: PayrollManageStore
    @Environment(\.dismiss) private var dismiss
    @State private var minRevenue: Double = 0
    @State private var maxRevenue: Double = 0
    @State private var rate: Double = 25
    @State private var noUpperLimit = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("最低營業額")
                                .font(.caption)
                            TextField("0", value: $minRevenue, format: .number)
                                .keyboardType(.numberPad)
                        }
                        VStack(alignment: .leading) {
                            Text("最高營業額")
                                .font(.caption)
                            if noUpperLimit {
                                Text("無上限").foregroundStyle(.secondary)
                            } else {
                                TextField("0", value: $maxRevenue, format: .number)
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                    Toggle("無上限", isOn: $noUpperLimit)
                }
                Section {
                    VStack(alignment: .leading) {
                        Text("抽成比例 (%)")
                            .font(.caption)
                        TextField("25", value: $rate, format: .number)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("新增階梯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        Task {
                            guard let settingId = store.commissionSettings?.id else { return }
                            var body: [String: Any] = [
                                "settingId": settingId,
                                "minRevenue": minRevenue,
                                "rate": rate / 100.0,
                                "sortOrder": store.commissionTiers.count
                            ]
                            if !noUpperLimit { body["maxRevenue"] = maxRevenue }
                            await store.createCommissionTier(body)
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct EditCommissionTierSheet: View {
    let store: PayrollManageStore
    let tier: CommissionTier
    @Environment(\.dismiss) private var dismiss
    @State private var minRevenue: Double = 0
    @State private var maxRevenue: Double = 0
    @State private var rate: Double = 0
    @State private var noUpperLimit = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("最低營業額").font(.caption)
                            TextField("0", value: $minRevenue, format: .number)
                                .keyboardType(.numberPad)
                        }
                        VStack(alignment: .leading) {
                            Text("最高營業額").font(.caption)
                            if noUpperLimit {
                                Text("無上限").foregroundStyle(.secondary)
                            } else {
                                TextField("0", value: $maxRevenue, format: .number)
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                    Toggle("無上限", isOn: $noUpperLimit)
                }
                Section {
                    VStack(alignment: .leading) {
                        Text("抽成比例 (%)").font(.caption)
                        TextField("0", value: $rate, format: .number)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("編輯階梯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        Task {
                            var body: [String: Any] = [
                                "minRevenue": minRevenue,
                                "rate": rate / 100.0
                            ]
                            if !noUpperLimit { body["maxRevenue"] = maxRevenue }
                            await store.updateCommissionTier(id: tier.id, body: body)
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                minRevenue = tier.minRevenue ?? 0
                maxRevenue = tier.maxRevenue ?? 0
                rate = (tier.rate ?? 0) * 100
                noUpperLimit = tier.maxRevenue == nil
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Tab 2: Staff Salary

private struct StaffSalaryTab: View {
    let store: PayrollManageStore
    let staffStore: StaffManageStore
    @State private var editingStaffId: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: BTSpacing.md) {
                ForEach(staffStore.staff) { member in
                    let config = store.salaryConfigs.first(where: { $0.staffId == member.id })
                    StaffSalaryCard(member: member, config: config) {
                        editingStaffId = member.id
                    }
                }
            }
            .padding(BTSpacing.lg)
        }
        .sheet(item: $editingStaffId) { staffId in
            let config = store.salaryConfigs.first(where: { $0.staffId == staffId })
            let member = staffStore.staff.first(where: { $0.id == staffId })
            EditSalarySheet(store: store, staffId: staffId, staffName: member?.name ?? "員工", config: config)
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

private struct StaffSalaryCard: View {
    let member: StaffMember
    let config: SalaryConfig?
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack {
                Text(member.name)
                    .font(.headline)
                Spacer()
                Button { onEdit() } label: {
                    Label("編輯", systemImage: "pencil.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let config {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    SalaryInfoItem(label: "底薪", value: Formatters.formatPrice(config.baseSalary ?? 0))
                    SalaryInfoItem(label: "津貼", value: Formatters.formatPrice(
                        (config.transportationAllowance ?? 0) +
                        (config.mealAllowance ?? 0) +
                        (config.otherAllowance ?? 0)
                    ))
                    SalaryInfoItem(
                        label: "抽成比例",
                        value: config.useCustomCommission == true
                            ? "\(Int((config.customCommissionRate ?? 0) * 100))% (個人)"
                            : "使用預設"
                    )
                    SalaryInfoItem(label: "指名獎金", value: "\(Formatters.formatPrice(config.designationBonus ?? 0))/次")
                }
            } else {
                Text("尚未設定薪資")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }
}

private struct SalaryInfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditSalarySheet: View {
    let store: PayrollManageStore
    let staffId: String
    let staffName: String
    let config: SalaryConfig?

    @Environment(\.dismiss) private var dismiss
    @State private var baseSalary: Double = 0
    @State private var transportation: Double = 0
    @State private var meal: Double = 0
    @State private var other: Double = 0
    @State private var useCustom: Bool = false
    @State private var customRate: Double = 0
    @State private var designationBonus: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        Text("底薪").font(.caption)
                        TextField("0", value: $baseSalary, format: .number)
                            .keyboardType(.numberPad)
                    }
                }

                Section("津貼") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("交通").font(.caption)
                            TextField("0", value: $transportation, format: .number)
                                .keyboardType(.numberPad)
                        }
                        VStack(alignment: .leading) {
                            Text("餐費").font(.caption)
                            TextField("0", value: $meal, format: .number)
                                .keyboardType(.numberPad)
                        }
                        VStack(alignment: .leading) {
                            Text("其他").font(.caption)
                            TextField("0", value: $other, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                }

                Section {
                    Toggle("使用個人抽成", isOn: $useCustom)
                    if useCustom {
                        VStack(alignment: .leading) {
                            Text("個人抽成比例 (%)").font(.caption)
                            TextField("0", value: $customRate, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading) {
                        Text("指名獎金 (/次)").font(.caption)
                        TextField("0", value: $designationBonus, format: .number)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("\(staffName) — 編輯薪資")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        Task {
                            let body: [String: Any] = [
                                "staffId": staffId,
                                "providerId": store.providerId,
                                "baseSalary": baseSalary,
                                "transportationAllowance": transportation,
                                "mealAllowance": meal,
                                "otherAllowance": other,
                                "useCustomCommission": useCustom,
                                "customCommissionRate": useCustom ? customRate / 100.0 : NSNull(),
                                "designationBonus": designationBonus
                            ]
                            await store.updateSalaryConfig(staffId: staffId, body: body)
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if let c = config {
                    baseSalary = c.baseSalary ?? 0
                    transportation = c.transportationAllowance ?? 0
                    meal = c.mealAllowance ?? 0
                    other = c.otherAllowance ?? 0
                    useCustom = c.useCustomCommission ?? false
                    customRate = (c.customCommissionRate ?? 0) * 100
                    designationBonus = c.designationBonus ?? 0
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Tab 3: Monthly Settlement

private struct MonthlySettlementTab: View {
    let store: PayrollManageStore

    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private let months = Array(1...12)
    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 2)...current)
    }

    private var totalSalary: Double {
        store.payrollRecords.reduce(0) { $0 + ($1.displayTotal) }
    }

    private var totalRevenue: Double {
        store.payrollRecords.reduce(0) { $0 + ($1.serviceRevenue ?? 0) }
    }

    private var currentStatus: PayrollStatus? {
        store.payrollRecords.first?.status
    }

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                // Year/Month Picker + Action Button
                HStack {
                    Picker("年", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(String(year))").tag(year)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("月", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text("\(month) 月").tag(month)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    if store.payrollRecords.isEmpty {
                        Button {
                            Task { await store.calculatePayroll(month: selectedMonth, year: selectedYear) }
                        } label: {
                            Text("產生結算")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primary)
                        .controlSize(.small)
                        .disabled(store.isLoading)
                    } else if currentStatus == .draft {
                        Button {
                            Task { await store.updatePayrollStatus(status: "confirmed", month: selectedMonth, year: selectedYear) }
                        } label: {
                            Label("全部確認", systemImage: "checkmark")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primary)
                        .controlSize(.small)
                        .disabled(store.isLoading)
                    } else if currentStatus == .confirmed {
                        Button {
                            Task { await store.updatePayrollStatus(status: "paid", month: selectedMonth, year: selectedYear) }
                        } label: {
                            Label("標記已發放", systemImage: "banknote")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primary)
                        .controlSize(.small)
                        .disabled(store.isLoading)
                    }
                }
                .padding(.horizontal, BTSpacing.lg)

                if store.payrollRecords.isEmpty {
                    Text("本月無結算紀錄，請先產生結算。")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    // Summary Cards
                    HStack(spacing: BTSpacing.md) {
                        SummaryCard(title: "本月薪資總額", value: Formatters.formatPrice(totalSalary))
                        SummaryCard(title: "本月總營業額", value: Formatters.formatPrice(totalRevenue))
                    }
                    .padding(.horizontal, BTSpacing.lg)

                    // Per-staff breakdown
                    ForEach(store.payrollRecords) { record in
                        PayrollRecordCard(record: record)
                    }
                    .padding(.horizontal, BTSpacing.lg)
                }
            }
            .padding(.vertical, BTSpacing.lg)
        }
        .task {
            await store.loadPayroll(month: selectedMonth, year: selectedYear)
        }
        .onChange(of: selectedMonth) { _, _ in
            Task { await store.loadPayroll(month: selectedMonth, year: selectedYear) }
        }
        .onChange(of: selectedYear) { _, _ in
            Task { await store.loadPayroll(month: selectedMonth, year: selectedYear) }
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: BTSpacing.sm) {
            Text(value)
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(BTSpacing.lg)
        .btCard()
    }
}

private struct PayrollRecordCard: View {
    let record: PayrollRecord

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            HStack {
                Text(record.staff?.name ?? "員工")
                    .font(.headline)
                Spacer()
                PayrollStatusBadge(status: record.status)
            }

            VStack(spacing: 6) {
                PayrollLineItem(label: "底薪", value: record.baseSalary)
                PayrollLineItem(label: "津貼", value: record.totalAllowances)
                PayrollLineItem(
                    label: "服務抽成 (\(Formatters.formatPrice(record.serviceRevenue ?? 0)))",
                    value: record.serviceCommission ?? record.commission
                )
            }

            Divider()

            HStack {
                Text("應發總額")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(Formatters.formatPrice(record.displayTotal))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BTColor.primary)
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }
}

private struct PayrollLineItem: View {
    let label: String
    let value: Double?

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(Formatters.formatPrice(value ?? 0))
                .font(.subheadline)
        }
    }
}

private struct PayrollStatusBadge: View {
    let status: PayrollStatus?

    private var statusText: String {
        switch status {
        case .draft: return "草稿"
        case .confirmed: return "已確認"
        case .paid: return "已發放"
        case .none: return "未知"
        }
    }

    private var statusColor: Color {
        switch status {
        case .draft: return .orange
        case .confirmed: return .blue
        case .paid: return .green
        case .none: return .gray
        }
    }

    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
}

// MARK: - Tab 4: Export

private struct ExportTab: View {
    let store: PayrollManageStore

    var body: some View {
        VStack(spacing: BTSpacing.xl) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("匯出薪資報表")
                .font(.headline)

            Text("將本月薪資明細匯出為 Excel 檔案。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                // TODO: Implement export - needs backend endpoint
            } label: {
                Label("下載 Excel", systemImage: "square.and.arrow.down")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(BTSpacing.lg)
    }
}

#Preview {
    NavigationStack {
        PayrollView()
            .environment(PayrollManageStore())
            .environment(StaffManageStore())
    }
}
