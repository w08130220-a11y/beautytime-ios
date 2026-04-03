import SwiftUI
import PhotosUI

struct BookingDetailView: View {
    let booking: Booking
    @State private var showCancelAlert = false
    @State private var showReviewSheet = false
    @State private var showDisputeSheet = false
    @State private var disputeReason = ""
    @State private var isLoading = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusBanner
                serviceInfo
                dateTimeInfo
                staffInfo
                priceInfo
                if let note = booking.note, !note.isEmpty {
                    noteSection(note)
                }
                actionButtons
            }
            .padding()
        }
        .navigationTitle("預約詳情")
        .navigationBarTitleDisplayMode(.inline)
        .alert("取消預約", isPresented: $showCancelAlert) {
            Button("確定取消", role: .destructive) {
                Task { await cancelBooking() }
            }
            Button("返回", role: .cancel) {}
        } message: {
            Text("確定要取消這筆預約嗎？此操作無法復原。")
        }
        .sheet(isPresented: $showReviewSheet) {
            WriteReviewSheet(booking: booking)
        }
        .alert("錯誤", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("確定") { error = nil }
        } message: {
            Text(error ?? "")
        }
        .alert("提出爭議", isPresented: $showDisputeSheet) {
            TextField("請說明爭議原因", text: $disputeReason)
            Button("送出", role: .destructive) {
                Task { await submitDispute() }
            }
            Button("取消", role: .cancel) { disputeReason = "" }
        } message: {
            Text("請描述您遇到的問題，我們會盡快處理。")
        }
    }

    private var statusBanner: some View {
        HStack {
            if let status = booking.status {
                Circle()
                    .fill(status.color)
                    .frame(width: 10, height: 10)
                Text(status.displayName)
                    .font(.headline)
                    .foregroundStyle(status.color)
            }
            Spacer()
            if let createdAt = booking.createdAt {
                Text(Formatters.relativeDate(createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var serviceInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("服務", systemImage: "sparkles")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(booking.service?.name ?? "—")
                .font(.title3)
                .fontWeight(.semibold)
            if let providerName = booking.provider?.name {
                Label(providerName, systemImage: "storefront")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dateTimeInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("日期", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(booking.date.map { Formatters.formatDate($0) } ?? "—")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Label("時間", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(booking.time ?? "—")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Label("時長", systemImage: "hourglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(booking.duration.map { "\($0) 分鐘" } ?? "—")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var staffInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("設計師", systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(booking.staff?.name ?? "不指定")
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var priceInfo: some View {
        VStack(spacing: 8) {
            HStack {
                Text("總金額")
                Spacer()
                Text(booking.totalPrice.map { Formatters.formatPrice($0) } ?? "—")
                    .fontWeight(.semibold)
            }
            if let deposit = booking.depositAmount, deposit > 0 {
                Divider()
                HStack {
                    Text("訂金")
                    Spacer()
                    HStack(spacing: 4) {
                        Text(Formatters.formatPrice(deposit))
                        if booking.depositPaid == true {
                            Text("已付")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("備註", systemImage: "note.text")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(note)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch booking.status {
        case .pending:
            Button("取消預約", role: .destructive) {
                showCancelAlert = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        case .completed:
            Button("撰寫評論") {
                showReviewSheet = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        case .confirmed:
            VStack(spacing: 12) {
                Button("取消預約", role: .destructive) {
                    showCancelAlert = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("提出爭議") {
                    showDisputeSheet = true
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .frame(maxWidth: .infinity)
            }
        default:
            EmptyView()
        }
    }

    private func cancelBooking() async {
        isLoading = true
        do {
            let _: SuccessResponse = try await api.patch(
                path: APIEndpoints.Bookings.cancel(booking.id),
                body: ["reason": "顧客取消"]
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func submitDispute() async {
        isLoading = true
        do {
            let _: SuccessResponse = try await api.patch(
                path: APIEndpoints.Bookings.dispute(booking.id),
                body: ["reason": disputeReason]
            )
            disputeReason = ""
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Write Review Sheet

struct WriteReviewSheet: View {
    let booking: Booking
    @State private var rating = 5
    @State private var comment = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var imageUrls: [String] = []
    @State private var isSubmitting = false
    @State private var submitError: String?
    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("評分") {
                    RatingInput(rating: $rating)
                        .frame(maxWidth: .infinity)
                }
                Section("評論") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                }
                Section("照片（最多 5 張）") {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label(
                            selectedPhotos.isEmpty ? "選擇照片" : "已選 \(selectedPhotos.count) 張",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                }
            }
            .navigationTitle("撰寫評論")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("送出") {
                        Task { await submitReview() }
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("錯誤", isPresented: Binding(
                get: { submitError != nil },
                set: { if !$0 { submitError = nil } }
            )) {
                Button("確定") { submitError = nil }
            } message: {
                Text(submitError ?? "")
            }
        }
    }

    private func submitReview() async {
        isSubmitting = true
        do {
            // Upload photos first
            var uploadedUrls: [String] = []
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let base64 = data.base64EncodedString()
                    let response: ImageUploadResponse = try await api.post(
                        path: APIEndpoints.Portfolio.upload,
                        body: JSONBody([
                            "fileName": "review_\(UUID().uuidString).jpg",
                            "contentType": "image/jpeg",
                            "fileData": base64
                        ] as [String: Any])
                    )
                    if let url = response.url ?? response.imageUrl {
                        uploadedUrls.append(url)
                    }
                }
            }

            var dict: [String: Any] = [
                "bookingId": booking.id,
                "customerId": booking.customerId ?? "",
                "providerId": booking.providerId ?? "",
                "rating": rating
            ]
            if !comment.isEmpty { dict["comment"] = comment }
            if let staffId = booking.staffId { dict["staffId"] = staffId }
            if !uploadedUrls.isEmpty { dict["imageUrls"] = uploadedUrls }

            let _: Review = try await api.post(path: APIEndpoints.Reviews.create, body: JSONBody(dict))
            dismiss()
        } catch {
            submitError = "送出失敗：\(error.localizedDescription)"
        }
        isSubmitting = false
    }
}
