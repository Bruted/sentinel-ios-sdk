# Redeyed Sentinel — iOS CAPTCHA SDK

Render the **Redeyed Sentinel** CAPTCHA inside a native `WKWebView` and get the
verification token back in Swift. Ships as a SwiftUI `UIViewRepresentable`.

> **Free to use — but you need keys.** Create a Sentinel **site key** (public,
> safe to ship) and a secret **API key** (server-only) in the
> [Redeyed Lab](https://redeyed.com/lab). The SDK only renders the widget and
> returns a token; **verification happens on your server.**

---

## Install (Swift Package Manager)

In Xcode: **File → Add Package Dependencies…** and paste the repository URL:

```
https://github.com/bruted/sentinel-ios-sdk.git
```

Or add it to your `Package.swift`:

```swift
.package(url: "https://github.com/bruted/sentinel-ios-sdk.git", from: "1.0.0")
```

Requires **iOS 15+**. No external dependencies.

---

## Usage (SwiftUI)

```swift
import SwiftUI
import RedeyedCaptcha

struct SignUpView: View {
    var body: some View {
        SentinelCaptchaView(siteKey: "redeyed-web") { token in
            // Send to YOUR server — never verify in the app.
            sendTokenToServer(token)
        }
        .frame(height: 120)
    }
}
```

With optional widget/theme/scheme and an error handler:

```swift
SentinelCaptchaView(
    siteKey: "redeyed-web",
    widget: "behavioral",   // optional
    theme:  "auto",          // optional
    scheme: "default",       // optional
    // baseURL defaults to https://redeyed.com
    onError: { error in print("Captcha failed: \(error)") },
    onToken: { token in sendTokenToServer(token) }
)
```

Or pass a configuration value:

```swift
let config = SentinelCaptcha(siteKey: "redeyed-web", theme: "dark")
SentinelCaptchaView(config: config) { token in sendTokenToServer(token) }
```

---

## Server-side verification (required)

The app must **never** hold your secret API key. After you receive the token,
POST it from your backend:

```
POST {baseURL}/api/v1/verify          (default baseURL: https://redeyed.com)
Headers:
    X-Api-Key: <YOUR SECRET API KEY>
    Content-Type: application/json
Body:
    { "site_key": "redeyed-web", "token": "<token from the SDK>" }
```

The verification **succeeds** when the response has
`data.success === true` (or `success === true`). Only then should you treat the
user as human.

---

## How it works

The view loads an inline HTML document into a `WKWebView` containing:

```html
<script src="{baseURL}/sentinel.js" async></script>
<div class="sentinel-captcha" data-sitekey="{siteKey}" ...></div>
```

Inside that page it listens for the bubbling `sentinel:solved` CustomEvent
(token in `event.detail.token`), with a fallback that reads the injected hidden
`sentinel-token` input. The token is bridged to native via a
`WKScriptMessageHandler` named **`sentinel`**
(`window.webkit.messageHandlers.sentinel.postMessage(token)`) → your `onToken`
closure. The site key is HTML-attribute-escaped before being injected.

## License

MIT © 2026 Redeyed. See [LICENSE](LICENSE).
