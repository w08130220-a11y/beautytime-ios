import SwiftUI
import WebKit

struct ECPayWebView: UIViewRepresentable {
    let html: String
    var onPaymentComplete: ((String) -> Void)?
    var onTimeout: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onPaymentComplete: onPaymentComplete, onTimeout: onTimeout)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(html, baseURL: nil)
        context.coordinator.startTimeoutTimer()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let onPaymentComplete: ((String) -> Void)?
        let onTimeout: (() -> Void)?
        private var timeoutTask: Task<Void, Never>?

        init(onPaymentComplete: ((String) -> Void)?, onTimeout: (() -> Void)?) {
            self.onPaymentComplete = onPaymentComplete
            self.onTimeout = onTimeout
        }

        func startTimeoutTimer() {
            timeoutTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 120 * 1_000_000_000) // 120 seconds
                guard !Task.isCancelled else { return }
                onTimeout?()
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.absoluteString.contains("/payments/result") {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                if let tradeNo = components?.queryItems?.first(where: { $0.name == "merchantTradeNo" })?.value {
                    timeoutTask?.cancel()
                    onPaymentComplete?(tradeNo)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Network drop during payment
            timeoutTask?.cancel()
        }

        deinit {
            timeoutTask?.cancel()
        }
    }
}

struct PaymentWebViewSheet: View {
    let html: String
    let onComplete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showTimeout = false
    @State private var showCancelConfirm = false

    var body: some View {
        NavigationStack {
            ECPayWebView(
                html: html,
                onPaymentComplete: { tradeNo in
                    onComplete(tradeNo)
                    dismiss()
                },
                onTimeout: {
                    showTimeout = true
                }
            )
            .navigationTitle("付款")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showCancelConfirm = true }
                }
            }
            .alert("付款逾時", isPresented: $showTimeout) {
                Button("重試") {
                    showTimeout = false
                }
                Button("取消付款", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("付款頁面逾時，請確認網路連線後重試。")
            }
            .confirmationDialog("確定要取消付款嗎？", isPresented: $showCancelConfirm) {
                Button("取消付款", role: .destructive) { dismiss() }
                Button("繼續付款", role: .cancel) {}
            } message: {
                Text("如果已完成付款但尚未返回，您的付款不會遺失。")
            }
        }
    }
}
