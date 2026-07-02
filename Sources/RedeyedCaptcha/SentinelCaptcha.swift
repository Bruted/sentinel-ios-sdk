import Foundation

/// Immutable configuration for a Sentinel CAPTCHA widget.
///
/// The only required value is the public ``siteKey`` you create in the
/// Redeyed Lab (https://redeyed.com/lab) → Sentinel → Sites. The site key is
/// **public** and safe to ship inside the app. Your **Secret Key is never used
/// in the app** — verification happens on your own server (see the README).
public struct SentinelCaptcha: Equatable {

    /// Default origin that serves `sentinel.js`.
    public static let defaultBaseURL = "https://redeyed.com"

    /// Public Sentinel site key, e.g. `"redeyed-web"`.
    public let siteKey: String

    /// Optional widget type (e.g. `"behavioral"`) → `data-widget`.
    public let widget: String?

    /// Optional theme (e.g. `"auto"`, `"light"`, `"dark"`) → `data-theme`.
    public let theme: String?

    /// Optional colour scheme (e.g. `"default"`) → `data-scheme`.
    public let scheme: String?

    /// Origin serving `sentinel.js`. Defaults to ``defaultBaseURL``.
    public let baseURL: String

    /// Creates a configuration. Only `siteKey` is required.
    public init(
        siteKey: String,
        widget: String? = nil,
        theme: String? = nil,
        scheme: String? = nil,
        baseURL: String = SentinelCaptcha.defaultBaseURL
    ) {
        self.siteKey = siteKey
        self.widget = widget
        self.theme = theme
        self.scheme = scheme
        self.baseURL = baseURL
    }
}
