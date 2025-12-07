// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BRFullTextSearch",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "BRFullTextSearch",
            targets: ["BRFullTextSearch"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "BRFullTextSearch",
            path: "Artifacts/BRFullTextSearch.xcframework"
        )
    ]
)
