import SwiftUI
import AVFoundation

/// Merchant-side: scans the consumer's check-in QR Code to confirm arrival.
/// Parses: beautytime://checkin/{bookingId}/{token}
struct CheckinScanView: View {
    @Environment(OrderManageStore.self) private var orderStore
    @State private var scannedResult: String?
    @State private var checkinSuccess = false
    @State private var checkinError: String?
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 0) {
            if checkinSuccess {
                checkinSuccessView
            } else {
                // Camera scanner
                QRScannerView(onScan: handleScan)
                    .ignoresSafeArea()

                // Bottom info
                VStack(spacing: 12) {
                    Text("掃描客人的 QR Code")
                        .font(.headline)
                    Text("請對準客人手機上的 Check-in QR Code")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if isProcessing {
                        ProgressView("驗證中...")
                    }

                    if let error = checkinError {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("掃碼報到")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var checkinSuccessView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("報到成功！")
                .font(.title)
                .fontWeight(.bold)
            Text("客人已確認到店")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func handleScan(_ code: String) {
        guard !isProcessing else { return }

        // Parse: beautytime://checkin/{bookingId}/{token}
        guard let url = URL(string: code),
              url.scheme == "beautytime",
              url.host == "checkin",
              url.pathComponents.count >= 3 else {
            checkinError = "無效的 QR Code"
            return
        }

        let bookingId = url.pathComponents[1]
        let token = url.pathComponents[2]

        isProcessing = true
        checkinError = nil

        Task {
            await orderStore.checkinBooking(id: bookingId, token: token)
            if orderStore.error == nil {
                checkinSuccess = true
                BookingAlertService.shared.playBookingSound()
            } else {
                checkinError = orderStore.error
            }
            isProcessing = false
        }
    }
}

// MARK: - QR Scanner (AVCaptureSession wrapper)

struct QRScannerView: UIViewRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }

        let session = AVCaptureSession()
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)

        context.coordinator.session = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScan: (String) -> Void
        var session: AVCaptureSession?
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else { return }
            hasScanned = true
            session?.stopRunning()
            onScan(value)
        }
    }
}
