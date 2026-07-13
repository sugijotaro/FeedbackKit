// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FeedbackKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FeedbackKit",
            targets: ["FeedbackKit"]
        )
    ],
    targets: [
        .target(
            name: "FeedbackKit",
            resources: [
                .process("Localizable.xcstrings")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
