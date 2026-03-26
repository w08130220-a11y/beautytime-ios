import SwiftUI

// MARK: - Filter Tab

enum VoucherFilterTab: Int, CaseIterable {
    case all
    case active
    case expired

    var title: String {
        switch self {
        case .all: return "全部"
        case .active: return "使用中"
        case .expired: return "已過期"
        }
    }
}

// MARK: - My Vouchers View

struct MyVouchersView: View {
    @State private var vouchers: [CustomerVoucher] = []
    @State private var selectedTab: VoucherFilterTab = .all
    @State private var isLoading = false
    @State private var error: String?

    private let api = APIClient.shared

    var filteredVouchers: [CustomerVoucher] {
        switch selectedTab {
        case .all:
            return vouchers
        case .active:
            return vouchers.filter { $0.status == .active || $0.status == .frozen || $0.status == .pending }
        case .expired:
            return vouchers.filter { $0.status == .expired || $0.status == .refunded }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("篩選", selection: $selectedTab) {
                    ForEach(VoucherFilterTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                voucherList
            }
            .navigationTitle("我的票券")
            .task { await loadVouchers() }
            .refreshable { await loadVouchers() }
        }
    }

    @ViewBuilder
    private var voucherList: some View {
        if isLoading && vouchers.isEmpty {
            LoadingView()
        } else if let error, vouchers.isEmpty {
            ErrorView(message: error) {
                Task { await loadVouchers() }
            }
        } else if filteredVouchers.isEmpty {
            EmptyStateView(
                icon: "ticket",
                title: "沒有票券",
                message: selectedTab == .active ? "你目前沒有使用中的票券" : "沒有已過期的票券"
            )
        } else {
            List(filteredVouchers) { voucher in
                NavigationLink {
                    VoucherDetailView(voucher: voucher)
                } label: {
                    VoucherRow(voucher: voucher)
                }
            }
            .listStyle(.plain)
        }
    }

    private func loadVouchers() async {
        isLoading = true
        error = nil
        do {
            vouchers = try await api.get(path: APIEndpoints.Vouchers.my)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Voucher Row

struct VoucherRow: View {
    let voucher: CustomerVoucher

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Plan name + status badge
            HStack {
                Text(voucher.plan?.name ?? "票券")
                    .font(.headline)
                Spacer()
                if let status = voucher.status {
                    Text(status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status.color.opacity(0.15))
                        .foregroundStyle(status.color)
                        .clipShape(Capsule())
                }
            }

            // Provider name + voucher type badge
            HStack {
                if let providerName = voucher.provider?.name {
                    Label(providerName, systemImage: "storefront")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let type = voucher.plan?.type {
                    Text(type.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }

            // Usage info
            usageInfo

            // Expiry date
            if let expiresAt = voucher.expiresAt {
                HStack {
                    Label(formatExpiryDate(expiresAt), systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundStyle(isExpiringSoon(expiresAt) ? .orange : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var usageInfo: some View {
        switch voucher.plan?.type {
        case .session:
            if let remaining = voucher.sessionsRemaining {
                Label("剩餘 \(remaining) 次", systemImage: "number.circle")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        case .storedValue:
            if let balance = voucher.balanceRemaining {
                Label("餘額 \(Formatters.formatPrice(balance))", systemImage: "dollarsign.circle")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        case .package:
            if let remaining = voucher.packageRemaining, !remaining.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(remaining.sorted(by: { $0.key < $1.key }), id: \.key) { serviceName, count in
                        Label("\(serviceName)：剩餘 \(count) 次", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        case .none:
            EmptyView()
        }
    }

    private func formatExpiryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "zh_TW")
        return "到期日：\(formatter.string(from: date))"
    }

    private func isExpiringSoon(_ date: Date) -> Bool {
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysRemaining >= 0 && daysRemaining <= 14
    }
}
