import SwiftUI

struct ManageView: View {
    @State private var manageStore = ManageStore()
    @State private var dashboardStore = DashboardStore()
    @State private var orderStore = OrderManageStore()
    @State private var customerStore = CustomerManageStore()
    @State private var staffStore = StaffManageStore()
    @State private var analyticsStore = AnalyticsManageStore()
    @State private var payrollStore = PayrollManageStore()
    @State private var voucherStore = VoucherManageStore()
    @Environment(AuthStore.self) private var authStore

    var body: some View {
        NavigationStack {
            List {
                Section("總覽") {
                    NavigationLink {
                        DashboardView()
                            .environment(dashboardStore)
                            .environment(staffStore)
                    } label: {
                        Label("儀表板", systemImage: "chart.bar.fill")
                    }
                    NavigationLink {
                        ScheduleView()
                            .environment(dashboardStore)
                            .environment(orderStore)
                            .environment(staffStore)
                    } label: {
                        Label("排班管理", systemImage: "calendar")
                    }
                }

                Section("服務管理") {
                    NavigationLink {
                        ServicesManageView()
                            .environment(manageStore)
                    } label: {
                        Label("服務項目", systemImage: "sparkles")
                    }
                    NavigationLink {
                        StaffManageView()
                            .environment(staffStore)
                    } label: {
                        Label("員工管理", systemImage: "person.2.fill")
                    }
                    NavigationLink {
                        StaffInvitationsView()
                            .environment(staffStore)
                    } label: {
                        Label("員工邀請", systemImage: "envelope.badge.person.crop")
                    }
                    NavigationLink {
                        StaffScheduleEditView()
                            .environment(staffStore)
                    } label: {
                        Label("排班與請假", systemImage: "calendar.badge.clock")
                    }
                    NavigationLink {
                        TimeSlotBlockView()
                            .environment(staffStore)
                    } label: {
                        Label("封鎖時段", systemImage: "clock.badge.xmark")
                    }
                    NavigationLink {
                        OrdersManageView()
                            .environment(orderStore)
                    } label: {
                        Label("訂單管理", systemImage: "list.clipboard.fill")
                    }
                    NavigationLink {
                        CustomersView()
                            .environment(customerStore)
                    } label: {
                        Label("顧客管理", systemImage: "person.crop.rectangle.stack.fill")
                    }
                    NavigationLink {
                        MatchOffersView()
                            .environment(manageStore)
                    } label: {
                        Label("媒合需求", systemImage: "person.2.wave.2.fill")
                    }
                }

                Section("行銷與內容") {
                    NavigationLink {
                        PortfolioManageView()
                            .environment(manageStore)
                    } label: {
                        Label("作品集", systemImage: "photo.on.rectangle.angled")
                    }
                    NavigationLink {
                        VoucherPlansView()
                            .environment(voucherStore)
                    } label: {
                        Label("票券方案", systemImage: "ticket.fill")
                    }
                    NavigationLink {
                        MarketingView()
                            .environment(manageStore)
                    } label: {
                        Label("行銷工具", systemImage: "megaphone.fill")
                    }
                }

                Section("數據與報表") {
                    NavigationLink {
                        AnalyticsView()
                            .environment(analyticsStore)
                    } label: {
                        Label("營收分析", systemImage: "chart.pie.fill")
                    }
                    NavigationLink {
                        PerformanceView()
                            .environment(staffStore)
                    } label: {
                        Label("員工績效", systemImage: "chart.bar.xaxis")
                    }
                    NavigationLink {
                        PayrollView()
                            .environment(payrollStore)
                            .environment(staffStore)
                    } label: {
                        Label("薪資管理", systemImage: "dollarsign.circle.fill")
                    }
                }

                Section("設定") {
                    NavigationLink {
                        BusinessHoursView()
                            .environment(manageStore)
                    } label: {
                        Label("營業時間", systemImage: "clock.fill")
                    }
                    NavigationLink {
                        ManageNotificationsView()
                            .environment(manageStore)
                    } label: {
                        Label("通知設定", systemImage: "bell.badge.fill")
                    }
                    NavigationLink {
                        ProviderSettingsView()
                            .environment(manageStore)
                    } label: {
                        Label("商家設定", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("管理後台")
        }
        .task {
            // Fetch provider profile for current user
            await loadProviderProfile()
        }
    }

    private func loadProviderProfile() async {
        do {
            let provider: Provider = try await APIClient.shared.get(
                path: APIEndpoints.Providers.me
            )
            setProviderId(provider.id)
        } catch {
            // Fallback: check staff role
            do {
                struct StaffRoleResponse: Codable {
                    let role: String?
                    let staffId: String?
                    let providerId: String?
                }
                let roleInfo: StaffRoleResponse = try await APIClient.shared.get(
                    path: APIEndpoints.Providers.myStaffRole
                )
                if let pid = roleInfo.providerId {
                    setProviderId(pid)
                }
            } catch {
                print("[ManageView] Failed to load provider: \(error)")
            }
        }
    }

    private func setProviderId(_ id: String) {
        manageStore.providerId = id
        dashboardStore.providerId = id
        orderStore.providerId = id
        customerStore.providerId = id
        staffStore.providerId = id
        analyticsStore.providerId = id
        payrollStore.providerId = id
        voucherStore.providerId = id
    }
}
