import SwiftUI
import GoogleSignIn

@main
struct BeautyTimeApp: App {
    @State private var authStore = AuthStore()
    @State private var userStore = UserStore()
    @State private var providerStore = ProviderStore()
    @State private var notificationStore = NotificationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authStore)
                .environment(userStore)
                .environment(providerStore)
                .environment(notificationStore)
                .task {
                    if authStore.isAuthenticated {
                        await authStore.fetchCurrentUser()
                        userStore.currentUser = authStore.currentUser
                    }
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
