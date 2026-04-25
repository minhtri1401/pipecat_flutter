// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pipecat",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "pipecat", targets: ["pipecat"])
    ],
    dependencies: [
        .package(url: "https://github.com/pipecat-ai/pipecat-client-ios",             from: "1.2.0"),
        .package(url: "https://github.com/pipecat-ai/pipecat-client-ios-daily",       from: "1.2.0"),
        .package(url: "https://github.com/pipecat-ai/pipecat-client-ios-small-webrtc", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "pipecat",
            dependencies: [
                .product(name: "PipecatClientIOS",          package: "pipecat-client-ios"),
                .product(name: "PipecatClientIOSDaily",     package: "pipecat-client-ios-daily"),
                .product(name: "PipecatClientIOSSmallWebrtc", package: "pipecat-client-ios-small-webrtc"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
    ]
)
