import SwiftUI
import WebKit

// MARK: - HTML building (shared)

/// Builds the inline HTML document that hosts the Sentinel widget.
/// Kept free of UIKit/SwiftUI so it can be reused and unit-tested.
enum SentinelHTML {

    /// Minimal, safe HTML attribute escaping for values placed inside "…".
    static func escapeAttribute(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Produce the full HTML document for a given configuration.
    static func document(for config: SentinelCaptcha) -> String {
        var attrs = " data-sitekey=\"\(escapeAttribute(config.siteKey))\""
        if let widget = config.widget {
            attrs += " data-widget=\"\(escapeAttribute(widget))\""
        }
        if let theme = config.theme {
            attrs += " data-theme=\"\(escapeAttribute(theme))\""
        }
        if let scheme = config.scheme {
            attrs += " data-scheme=\"\(escapeAttribute(scheme))\""
        }
        if let difficulty = config.difficulty {
            attrs += " data-difficulty=\"\(escapeAttribute(difficulty))\""
        }
        if let width = config.width {
            attrs += " data-width=\"\(escapeAttribute(width))\""
        }
        let scriptSrc = escapeAttribute("\(config.baseURL)/sentinel.js")

        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <style>
            html,body{margin:0;padding:0;background:transparent;}
            .wrap{display:flex;justify-content:center;padding:8px;}
          </style>
        </head>
        <body>
          <div class="wrap">
            <div class="sentinel-captcha"\(attrs)></div>
          </div>
          <script src="\(scriptSrc)" async></script>
          <script>
            (function () {
              var sent = false;
              function emit(token) {
                if (sent || !token) return;
                sent = true;
                try {
                  window.webkit.messageHandlers.sentinel.postMessage(String(token));
                } catch (e) {}
              }
              // Primary path: the bubbling CustomEvent.
              document.addEventListener('sentinel:solved', function (e) {
                emit(e && e.detail && e.detail.token);
              }, true);
              // Fallback path: poll the injected hidden input.
              var poll = setInterval(function () {
                var el = document.querySelector('input[name="sentinel-token"], #sentinel-token, .sentinel-token');
                if (el && el.value) { emit(el.value); clearInterval(poll); }
              }, 400);
            })();
          </script>
        </body>
        </html>
        """
    }
}

// MARK: - UIViewRepresentable (SwiftUI)

/// A SwiftUI view that renders the Redeyed **Sentinel** CAPTCHA inside a
/// `WKWebView` and returns the verification token via ``onToken``.
///
/// The view performs **no verification** — send the token to *your own server*,
/// which calls `POST {baseURL}/sentinel/siteverify` with a JSON body of
/// `{ "secret": "<SECRET KEY>", "response": "<token>" }` (optional `"remoteip"`).
/// The Secret Key must never live in the app.
///
/// ```swift
/// SentinelCaptchaView(siteKey: "redeyed-web") { token in
///     // POST token to your backend
/// }
/// ```
public struct SentinelCaptchaView: UIViewRepresentable {

    private let config: SentinelCaptcha
    private let onToken: (String) -> Void
    private let onError: ((Error) -> Void)?

    /// Create with an explicit configuration.
    public init(
        config: SentinelCaptcha,
        onError: ((Error) -> Void)? = nil,
        onToken: @escaping (String) -> Void
    ) {
        self.config = config
        self.onToken = onToken
        self.onError = onError
    }

    /// Convenience initialiser taking just a site key (+ optional fields).
    public init(
        siteKey: String,
        widget: String? = nil,
        theme: String? = nil,
        scheme: String? = nil,
        difficulty: String? = nil,
        width: String? = nil,
        baseURL: String = SentinelCaptcha.defaultBaseURL,
        onError: ((Error) -> Void)? = nil,
        onToken: @escaping (String) -> Void
    ) {
        self.init(
            config: SentinelCaptcha(
                siteKey: siteKey,
                widget: widget,
                theme: theme,
                scheme: scheme,
                difficulty: difficulty,
                width: width,
                baseURL: baseURL
            ),
            onError: onError,
            onToken: onToken
        )
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onToken: onToken, onError: onError)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        // Bridge: the page calls window.webkit.messageHandlers.sentinel.postMessage(token)
        controller.add(context.coordinator, name: "sentinel")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        // sentinel.js needs JS; enable inline media just in case a widget uses it.
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false

        let html = SentinelHTML.document(for: config)
        // baseURL gives sentinel.js the correct origin for relative resources.
        webView.loadHTMLString(html, baseURL: URL(string: config.baseURL))
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        // Configuration is immutable per instance; nothing to update.
    }

    /// Detach the message handler when the view goes away to avoid a retain
    /// cycle through the user content controller.
    public static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: "sentinel")
    }

    // MARK: Coordinator

    public final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        private let onToken: (String) -> Void
        private let onError: ((Error) -> Void)?
        private var didSend = false

        init(onToken: @escaping (String) -> Void, onError: ((Error) -> Void)?) {
            self.onToken = onToken
            self.onError = onError
        }

        // JS → native token bridge.
        public func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "sentinel" else { return }
            guard let token = message.body as? String, !token.isEmpty else { return }
            guard !didSend else { return }
            didSend = true
            onToken(token)
        }

        // Surface hard load failures (no network, bad host, etc.).
        public func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            onError?(error)
        }

        public func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            onError?(error)
        }
    }
}
