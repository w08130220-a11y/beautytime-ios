import SwiftUI
import WebKit

struct ECPayWebView: UIViewRepresentable {
    let html: String
    var onPaymentComplete: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onPaymentComplete: onPaymentComplete)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let onPaymentComplete: ((String) -> Void)?

        init(onPaymentComplete: ((String) -> Void)?) {
            self.onPaymentComplete = onPaymentComplete
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.absoluteString.contains("/payments/result") {
                // Extract merchantTradeNo from URL
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                if let tradeNo = components?.queryItems?.first(where: { $0.name == "merchantTradeNo" })?.value {
                    onPaymentComplete?(tradeNo)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}

struct PaymentWebViewSheet: View {
    let html: String
    let onComplete: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ECPayWebView(html: html) { tradeNo in
                onComplete(tradeNo)
                dismiss()
            }
            .navigationTitle("付款")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
