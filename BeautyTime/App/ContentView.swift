import SwiftUI

struct ContentView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UserStore.self) private var userStore

    @State private var showSurvey = false

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                if showSurvey {
                    SurveyView(onComplete: {
                        showSurvey = false
                    })
                } else {
                    MainTabView()
                }
            } else {
                NavigationStack {
                    SignInView()
                }
            }
        }
        .task(id: authStore.isAuthenticated) {
            print("[ContentView] task 觸發, isAuthenticated=\(authStore.isAuthenticated), thread=\(Thread.isMainThread ? "main" : "bg")")
            if authStore.isAuthenticated {
                await authStore.fetchCurrentUser()
                userStore.currentUser = authStore.currentUser
                // Show survey if user hasn't completed it
                if authStore.currentUser?.surveyCompleted != true {
                    showSurvey = true
                }
            } else {
                userStore.currentUser = nil
                showSurvey = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthStore())
        .environment(UserStore())
}
