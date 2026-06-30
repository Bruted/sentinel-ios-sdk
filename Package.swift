// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "RedeyedCaptcha",
    platforms: [
        // WKWebView + SwiftUI features used here require iOS 15+.
        .iOS(.v15)
    ],
    products: [
        // A single library product consumers import as `RedeyedCaptcha`.
        .library(
            name: "RedeyedCaptcha",
            targets: ["RedeyedCaptcha"]
        )
    ],
    dependencies: [
        // No external dependencies — only Apple frameworks.
    ],
    targets: [
        .target(
            name: "RedeyedCaptcha",
            dependencies: []
        )
    ]
)
