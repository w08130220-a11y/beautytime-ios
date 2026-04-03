import SwiftUI

struct MatchListView: View {
    @State private var requests: [MatchRequest] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCreateSheet = false

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("配對需求")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("建立需求", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showCreateSheet) {
                    NavigationStack {
                        CreateMatchView {
                            await loadRequests()
                        }
                    }
                }
                .task { await loadRequests() }
                .refreshable { await loadRequests() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && requests.isEmpty {
            LoadingView()
        } else if let error, requests.isEmpty {
            ErrorView(message: error) {
                Task { await loadRequests() }
            }
        } else if requests.isEmpty {
            EmptyStateView(
                icon: "sparkle.magnifyingglass",
                title: "尚無配對需求",
                message: "建立需求讓美容師主動向你報價",
                actionTitle: "建立需求"
            ) {
                showCreateSheet = true
            }
        } else {
            List(requests) { request in
                NavigationLink {
                    MatchDetailView(requestId: request.id)
                } label: {
                    MatchRequestRow(request: request)
                }
            }
            .listStyle(.plain)
        }
    }

    private func loadRequests() async {
        isLoading = true
        error = nil
        do {
            requests = try await api.get(path: APIEndpoints.Match.myRequests)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - MatchRequestRow

private struct MatchRequestRow: View {
    let request: MatchRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let serviceType = request.serviceType,
                   let category = ServiceCategory(rawValue: serviceType) {
                    Label(category.displayName, systemImage: category.iconName)
                        .font(.headline)
                } else {
                    Text(request.serviceType ?? "服務")
                        .font(.headline)
                }
                Spacer()
                if let status = request.status {
                    StatusBadge(text: status.displayName, color: status.color)
                }
            }

            HStack {
                if let date = request.preferredDate {
                    Label(Formatters.formatDate(date), systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let time = request.preferredTime {
                    Label(time, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                if let city = request.locationCity,
                   let taiwanCity = TaiwanCity(rawValue: city) {
                    Label(taiwanCity.displayName, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                budgetText
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var budgetText: some View {
        if let min = request.budgetMin, let max = request.budgetMax {
            Text("\(Formatters.formatPrice(min)) – \(Formatters.formatPrice(max))")
                .font(.subheadline)
                .fontWeight(.semibold)
        } else if let min = request.budgetMin {
            Text("\(Formatters.formatPrice(min)) 起")
                .font(.subheadline)
                .fontWeight(.semibold)
        } else if let max = request.budgetMax {
            Text("最多 \(Formatters.formatPrice(max))")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    MatchListView()
}
