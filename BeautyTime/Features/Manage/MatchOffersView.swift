import SwiftUI

struct MatchOffersView: View {
    @Environment(ManageStore.self) private var manageStore

    @State private var requests: [MatchRequest] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedRequest: MatchRequest?

    private let api = APIClient.shared

    var body: some View {
        Group {
            if isLoading && requests.isEmpty {
                ProgressView("載入中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if requests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("沒有可報價的需求")
                        .font(.headline)
                    Text("目前沒有新的媒合需求")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(requests) { request in
                    MatchRequestRow(request: request)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRequest = request
                        }
                }
                .refreshable {
                    await loadRequests()
                }
            }
        }
        .navigationTitle("媒合需求")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRequests()
        }
        .sheet(item: $selectedRequest) { request in
            NavigationStack {
                SendOfferView(request: request, providerId: manageStore.providerId) {
                    await loadRequests()
                }
            }
        }
    }

    private func loadRequests() async {
        isLoading = true
        do {
            requests = try await api.get(path: APIEndpoints.Match.available)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Match Request Row

private struct MatchRequestRow: View {
    let request: MatchRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.serviceType ?? "未指定")
                    .font(.headline)
                Spacer()
                if let status = request.status {
                    Text(status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(status.color.opacity(0.15))
                        .foregroundStyle(status.color)
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                if let date = request.preferredDate {
                    Label(date, systemImage: "calendar")
                        .font(.caption)
                }
                if let time = request.preferredTime {
                    Label(time, systemImage: "clock")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                if let city = request.locationCity {
                    Label(city, systemImage: "mappin")
                        .font(.caption)
                }
                if let min = request.budgetMin, let max = request.budgetMax {
                    Label("\(Formatters.formatPrice(min)) - \(Formatters.formatPrice(max))", systemImage: "dollarsign.circle")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)

            if let note = request.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Send Offer View

private struct SendOfferView: View {
    @Environment(\.dismiss) private var dismiss

    let request: MatchRequest
    let providerId: String
    let onSubmitted: () async -> Void

    @State private var quotedPrice = ""
    @State private var message = ""
    @State private var availableSlots: [String] = [""]
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var showSuccess = false

    private let api = APIClient.shared

    var body: some View {
        Form {
            Section(header: Text("需求資訊")) {
                LabeledContent("服務類型", value: request.serviceType ?? "未指定")
                if let date = request.preferredDate {
                    LabeledContent("希望日期", value: date)
                }
                if let time = request.preferredTime {
                    LabeledContent("希望時間", value: time)
                }
                if let min = request.budgetMin, let max = request.budgetMax {
                    LabeledContent("預算範圍", value: "\(Formatters.formatPrice(min)) - \(Formatters.formatPrice(max))")
                }
                if let note = request.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section(header: Text("報價金額 *")) {
                TextField("NT$", text: $quotedPrice)
                    .keyboardType(.numberPad)
            }

            Section(header: Text("可用時段")) {
                ForEach(availableSlots.indices, id: \.self) { index in
                    TextField("例：2026-03-25 14:00", text: $availableSlots[index])
                }
                Button("新增時段") {
                    availableSlots.append("")
                }
                .font(.caption)
            }

            Section(header: Text("附加訊息")) {
                TextEditor(text: $message)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("向顧客介紹您的服務...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            }

            if let error {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }

            Section {
                Button {
                    Task { await submitOffer() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting { ProgressView().tint(.white) }
                        Text("送出報價").fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(quotedPrice.isEmpty || isSubmitting)
                .listRowBackground(quotedPrice.isEmpty ? Color.pink.opacity(0.4) : Color.pink)
                .foregroundStyle(.white)
            }
        }
        .navigationTitle("送出報價")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
        }
        .alert("報價已送出", isPresented: $showSuccess) {
            Button("確定") {
                Task { await onSubmitted() }
                dismiss()
            }
        } message: {
            Text("顧客收到報價後會決定是否接受")
        }
    }

    private func submitOffer() async {
        isSubmitting = true
        error = nil

        guard let price = Double(quotedPrice) else {
            error = "請輸入有效金額"
            isSubmitting = false
            return
        }

        do {
            let slots = availableSlots.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            let body: [String: Any] = [
                "requestId": request.id,
                "providerId": providerId,
                "quotedPrice": price,
                "availableSlots": slots,
                "message": message
            ]
            let _: MatchOffer = try await api.post(
                path: APIEndpoints.Match.createOffer,
                body: JSONBody(body)
            )
            showSuccess = true
        } catch {
            self.error = "送出失敗：\(error.localizedDescription)"
        }

        isSubmitting = false
    }
}
