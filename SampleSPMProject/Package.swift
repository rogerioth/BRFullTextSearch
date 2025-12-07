// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SampleSPMProject",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/rogerioth/BRFullTextSearch.git", exact: "1.0.8")
    ],
    targets: [
        .executableTarget(
            name: "SampleSPMProject",
            dependencies: [
                .product(name: "BRFullTextSearch", package: "BRFullTextSearch")
            ]
        )
    ]
)
