// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClarityHub",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ClarityHubCore", targets: ["ClarityHubCore"])
    ],
    targets: [
        .target(name: "ClarityHubCore", path: "Sources/ClarityHubCore"),
        .testTarget(
            name: "ClarityHubCoreTests",
            dependencies: ["ClarityHubCore"],
            path: "Tests/ClarityHubCoreTests"
        )
    ]
)

