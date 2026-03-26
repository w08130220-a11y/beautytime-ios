import SwiftUI

struct PayrollView: View {
    @Environment(PayrollManageStore.self) private var store

    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private let months = Array(1...12)
    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 2)...current)
    }

    var body: some View {
        List {
            Section("選擇月份") {
                HStack {
                    Picker("年", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(String(year)) 年").tag(year)
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

                    Button {
                        Task {
                            await store.calculatePayroll(month: selectedMonth, year: selectedYear)
                        }
                    } label: {
                        Label("計算薪資", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(store.isLoading)
                }
            }

            Section("薪資明細") {
                if store.payrollRecords.isEmpty {
                    ContentUnavailableView(
                        "尚無薪資紀錄",
                        systemImage: "banknote",
                        description: Text("請先點擊「計算薪資」")
                    )
                } else {
                    ForEach(store.payrollRecords) { record in
                        PayrollRecordRow(record: record)
                    }
                }
            }

            if let settings = store.commissionSettings {
                Section("抽成設定") {
                    HStack {
                        Text("抽成比例")
                        Spacer()
                        Text("\(Int((settings.defaultCommissionRate ?? 0) * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("抽成類型")
                        Spacer()
                        Text(settings.commissionType == .flat ? "固定比例" : "階梯式")
                            .foregroundStyle(.secondary)
                    }
                    if let productRate = settings.productCommissionRate {
                        HStack {
                            Text("產品抽成")
                            Spacer()
                            Text("\(Int(productRate * 100))%")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Commission Tiers (for tiered commission)
                if settings.commissionType == .tiered {
                    Section("階梯抽成設定") {
                        if store.commissionTiers.isEmpty {
                            ContentUnavailableView(
                                "尚無階梯設定",
                                systemImage: "stairs",
                                description: Text("目前沒有階梯抽成設定")
                            )
                        } else {
                            ForEach(store.commissionTiers) { tier in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(Formatters.formatPrice(tier.minRevenue ?? 0)) ~ \(Formatters.formatPrice(tier.maxRevenue ?? 0))")
                                            .font(.subheadline)
                                        Text("抽成 \(Int((tier.rate ?? 0) * 100))%")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        Task { await store.deleteCommissionTier(id: tier.id) }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }

            // Payroll Status Actions
            if !store.payrollRecords.isEmpty {
                Section("薪資狀態操作") {
                    PayrollStatusButtons(store: store, month: selectedMonth, year: selectedYear)
                }
            }
        }
        .navigationTitle("薪資管理")
        .task {
            async let payrollTask: () = store.loadPayroll(month: selectedMonth, year: selectedYear)
            async let commissionTask: () = store.loadCommissionSettings()
            _ = await (payrollTask, commissionTask)
            await store.loadCommissionTiers()
        }
        .onChange(of: selectedMonth) { _, _ in
            Task { await store.loadPayroll(month: selectedMonth, year: selectedYear) }
        }
        .onChange(of: selectedYear) { _, _ in
            Task { await store.loadPayroll(month: selectedMonth, year: selectedYear) }
        }
    }
}

// MARK: - Payroll Record Row

private struct PayrollRecordRow: View {
    let record: PayrollRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.staff?.name ?? "員工")
                    .font(.headline)
                Spacer()
                PayrollStatusBadge(status: record.status)
            }

            HStack(spacing: 16) {
                PayrollDetail(label: "底薪", value: record.baseSalary)
                PayrollDetail(label: "抽成", value: record.commission)
                PayrollDetail(label: "扣除", value: record.deductions)
            }

            Divider()

            HStack {
                Text("總計")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(Formatters.formatPrice(record.totalAmount ?? 0))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Payroll Detail

private struct PayrollDetail: View {
    let label: String
    let value: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(Formatters.formatPrice(value ?? 0))
                .font(.subheadline)
        }
    }
}

// MARK: - Payroll Status Badge

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

// MARK: - Payroll Status Buttons

private struct PayrollStatusButtons: View {
    let store: PayrollManageStore
    let month: Int
    let year: Int

    private var currentStatus: PayrollStatus? {
        store.payrollRecords.first?.status
    }

    var body: some View {
        VStack(spacing: 12) {
            if currentStatus == .draft {
                Button {
                    Task { await store.updatePayrollStatus(status: "confirmed") }
                } label: {
                    HStack {
                        Spacer()
                        Label("確認薪資", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(store.isLoading)
            }

            if currentStatus == .confirmed {
                Button {
                    Task { await store.updatePayrollStatus(status: "paid") }
                } label: {
                    HStack {
                        Spacer()
                        Label("標記已發放", systemImage: "banknote.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(store.isLoading)
            }

            if currentStatus == .paid {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("本月薪資已發放完成")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PayrollView()
            .environment(PayrollManageStore())
    }
}
