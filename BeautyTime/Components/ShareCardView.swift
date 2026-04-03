import SwiftUI

/// Generates a shareable card image with provider info, services, QR code, and booking link.
/// Merchants can share this to LINE/IG as a digital business card.
struct ShareCardView: View {
    let providerName: String
    let category: String
    let address: String
    let bookingURL: String

    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            cardContent
                .padding(24)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        )
        .padding()
    }

    private var cardContent: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text(providerName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Address
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.pink)
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // QR Code
            QRCodeView(content: bookingURL)
                .frame(width: 120, height: 120)

            // CTA
            Text("掃描預約")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Share button
            Button {
                showShareSheet = true
            } label: {
                Label("分享名片", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "\(providerName) - 線上預約\n\(bookingURL)"
            ])
        }
    }
}

/// UIActivityViewController wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ShareCardView(
        providerName: "Annlala 美甲美睫",
        category: "美甲 / 美睫 / 紋繡",
        address: "台北市大同區南京西路254號2F",
        bookingURL: "https://www.btbeautytime.com/providers/abc123/book"
    )
}
