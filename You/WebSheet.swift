import SwiftUI
import WebKit

struct WebSheet: View {
    var title: String
    var url: URL
    @State private var loading = true
    @State private var failed = false

    var body: some View {
        VStack(spacing: 0) {
            if loading {
                ProgressView()
                    .padding()
            }
            if failed {
                ContentUnavailableView("Couldn’t load the page", systemImage: "wifi.slash", description: Text("Check your connection and try again."))
                Button("Retry") { failed = false; loading = true }
                    .padding(.bottom)
            }
            WebView(url: url, loading: $loading, failed: $failed)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    var url: URL
    @Binding var loading: Bool
    @Binding var failed: Bool

    func makeCoordinator() -> Watcher { Watcher(loading: $loading, failed: $failed) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Watcher: NSObject, WKNavigationDelegate {
        var loading: Binding<Bool>
        var failed: Binding<Bool>

        init(loading: Binding<Bool>, failed: Binding<Bool>) {
            self.loading = loading
            self.failed = failed
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loading.wrappedValue = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            loading.wrappedValue = false
            failed.wrappedValue = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            loading.wrappedValue = false
            failed.wrappedValue = true
        }
    }
}
