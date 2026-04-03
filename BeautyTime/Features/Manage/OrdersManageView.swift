import SwiftUI

struct OrdersManageView: View {
    @Environment(OrderManageStore.self) private var store

    @State private var selectedFilter: OrderFilter = .all

    private enum OrderFilter: String, CaseIterable {
        case all = "全部"
        case pending = "待確認"
        case confirmed = "已確認"
        case completed = "已完成"
        case cancelled = "已取消"

        var bookingStatus: BookingStatus? {
            switch self {
            case .all: return nil
            case .pending: return .pending
            case .confirmed: return .confirmed
            case .completed: return .completed
            case .cancelled: return .cancelled
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterTabs
            Divider()
            ordersList
        }
        .navigationTitle("訂單管理")
        .task {
            await loadOrders()
        }
        .refreshable {
            await loadOrders()
        }
        .onChange(of: selectedFilter) { _, _ in
            Task { await loadOrders() }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OrderFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.accentColor : Color(.systemGray6))
                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Orders List

    private var ordersList: some View {
        List {
            if store.orders.isEmpty {
                ContentUnavailableView(
                    "無訂單",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("目前沒有符合條件的訂單")
                )
            } else {
                ForEach(store.orders) { order in
                    OrderRow(order: order, store: store)
                }
            }
        }
        .listStyle(.plain)
    }

    private func loadOrders() async {
        store.orderFilter = selectedFilter.bookingStatus
        await store.loadOrders()
    }
}

// MARK: - Order Row

private struct OrderRow: View {
    let order: Booking
    let store: ManageStore

    @State private var showCancelAlert = false
    @State private var cancelReason = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.customer?.fullName ?? "顧客")
                        .font(.headline)
                    Text(order.service?.name ?? "未知服務")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let status = order.status {
                    Text(status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(status.color.opacity(0.15))
                        .foregroundStyle(status.color)
                        .clipShape(Capsule())
                }
            }

            HStack {
                if let date = order.date {
                    Label(date, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let time = order.time {
                    Label(time, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let price = order.totalPrice {
                    Spacer()
                    Text(Formatters.formatPrice(price))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Action buttons
            if order.status == .pending || order.status == .confirmed {
                HStack(spacing: 12) {
                    Spacer()

                    Button {
                        showCancelAlert = true
                    } label: {
                        Label("取消", systemImage: "xmark.circle")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)

                    if order.status == .pending {
                        Button {
                            Task { await store.confirmBooking(id: order.id) }
                        } label: {
                            Label("確認", systemImage: "checkmark.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.small)
                    }

                    if order.status == .confirmed {
                        Button {
                            Task { await store.completeBooking(id: order.id) }
                        } label: {
                            Label("完成", systemImage: "checkmark.seal")
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .alert("取消訂單", isPresented: $showCancelAlert) {
            TextField("取消原因（必填）", text: $cancelReason)
            Button("確認取消", role: .destructive) {
                guard !cancelReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Task {
                    await store.cancelOrder(id: order.id, reason: cancelReason.trimmingCharacters(in: .whitespacesAndNewlines))
                    cancelReason = ""
                }
            }
            Button("返回", role: .cancel) {
                cancelReason = ""
            }
        } message: {
            Text("請輸入取消原因")
        }
    }
}

#Preview {
    NavigationStack {
        OrdersManageView()
            .environment(ManageStore())
    }
}
