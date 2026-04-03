import SwiftUI

/// Consumer-side: shows the check-in QR Code for the merchant to scan.
/// The QR contains a deep link: beautytime://checkin/{bookingId}/{token}
struct CheckinQRView: View {
    let booking: Booking

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("到店報到")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("請出示此 QR Code 給店家掃碼")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // QR Code
            if let token = booking.checkinToken {
                let qrContent = "beautytime://checkin/\(booking.id)/\(token)"
                QRCodeView(content: qrContent)
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.1), radius: 8)
                    )
            } else {
                // No token yet, show loading or fallback
                VStack(spacing: 12) {
                    ProgressView()
                    Text("正在生成 QR Code...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 200, height: 200)
            }

            // Booking info summary
            VStack(spacing: 8) {
                infoRow(icon: "scissors", label: booking.service?.name ?? "服務")
                infoRow(icon: "calendar", label: booking.date ?? "")
                infoRow(icon: "clock", label: booking.time ?? "")
                if let staff = booking.staff {
                    infoRow(icon: "person.fill", label: staff.name)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Already checked in
            if booking.checkinAt != nil {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("已完成報到")
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Check-in")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.subheadline)
            Spacer()
        }
    }
}
