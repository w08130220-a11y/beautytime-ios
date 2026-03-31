import SwiftUI

extension Notification.Name {
    static let switchToMyBookings = Notification.Name("switchToMyBookings")
}

struct MainTabView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UserStore.self) private var userStore
    @Environment(NotificationStore.self) private var notificationStore

    enum Tab {
        case explore
        case myBookings
        case match
        case profile
        case manage
    }

    @Environment(\.scenePhase) private var scenePhase
    @State var selectedTab: Tab = .explore

    private var showManageTab: Bool {
        let user = userStore.currentUser ?? authStore.currentUser
        guard let user else { return false }
        return user.role == .provider || user.role == .both
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ExploreView()
            }
            .tag(Tab.explore)
            .tabItem {
                Label("探索", systemImage: "magnifyingglass")
            }

            NavigationStack {
                MyBookingsView()
            }
            .tag(Tab.myBookings)
            .tabItem {
                Label("我的預約", systemImage: "calendar")
            }

            NavigationStack {
                MatchView()
            }
            .tag(Tab.match)
            .tabItem {
                Label("配對", systemImage: "person.2.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tag(Tab.profile)
            .tabItem {
                Label("個人", systemImage: "person.circle")
            }
            .badge(notificationStore.unreadCount > 0 ? notificationStore.unreadCount : 0)

            if showManageTab {
                ManageView()
                    .tag(Tab.manage)
                    .tabItem {
                        Label("管理", systemImage: "gearshape.2")
                    }
            }
        }
        .task {
            await notificationStore.loadNotifications()
            while !Task.isCancelled {
                if scenePhase == .active {
                    await notificationStore.loadNotifications()
                }
                try? await Task.sleep(for: .seconds(30))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToMyBookings)) { _ in
            selectedTab = .myBookings
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await notificationStore.loadNotifications()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(UserStore())
        .environment(NotificationStore())
}
