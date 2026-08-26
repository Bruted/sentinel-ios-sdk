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

    /// This SDK's semantic version.
    public static let version = "1.0.1"

    /// Public Sentinel site key, e.g. `"redeyed-web"`.
    public let siteKey: String

    /// Optional widget type (e.g. `"behavioral"`) → `data-widget`.
    public let widget: String?

    /// Optional theme (e.g. `"auto"`, `"light"`, `"dark"`) → `data-theme`.
    public let theme: String?

    /// Optional colour scheme → `data-scheme`. One of: `"default"`, `"ocean"`,
    /// `"forest"`, `"sunset"`, `"graphite"`, `"royalty"`, `"ruby"`, `"hacker"`,
    /// `"monochrome"`, `"midnight"`, `"aurora"`. (`"midnight"`/`"aurora"` are
    /// premium and the server enforces entitlement.)
    public let scheme: String?

    /// Optional challenge difficulty (`"easy"`, `"medium"`, `"hard"`, `"max"`,
    /// or `"1"`…`"6"`) → `data-difficulty`. Only raises difficulty above the
    /// adaptive baseline.
    public let difficulty: String?

    /// Optional widget width (e.g. `"full"`, `"100%"`, `"340px"`) →
    /// `data-width`. Emitted only when set.
    public let width: String?

    /// Origin serving `sentinel.js`. Defaults to ``defaultBaseURL``.
    public let baseURL: String

    /// Creates a configuration. Only `siteKey` is required.
    public init(
        siteKey: String,
        widget: String? = nil,
        theme: String? = nil,
        scheme: String? = nil,
        difficulty: String? = nil,
        width: String? = nil,
        baseURL: String = SentinelCaptcha.defaultBaseURL
    ) {
        self.siteKey = siteKey
        self.widget = widget
        self.theme = theme
        self.scheme = scheme
        self.difficulty = difficulty
        self.width = width
        self.baseURL = baseURL
    }
}
