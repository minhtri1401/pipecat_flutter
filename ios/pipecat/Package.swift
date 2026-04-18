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
    dependencies: [],
    targets: [
        .target(
            name: "pipecat",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
