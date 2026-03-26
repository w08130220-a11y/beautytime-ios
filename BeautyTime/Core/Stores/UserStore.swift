import Foundation
import Observation

@Observable
class UserStore {
    var currentUser: User?
    var isLoading: Bool = false
    var error: String?

    private let api = APIClient.shared

    func fetchCurrentUser() async {
        guard TokenManager.shared.hasToken else { return }
        isLoading = true
        do {
            let user: User = try await api.get(path: APIEndpoints.Auth.me)
            self.currentUser = user
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func clearUser() {
        currentUser = nil
        error = nil
    }
}
