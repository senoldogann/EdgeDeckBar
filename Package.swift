// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EdgeDeck",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "EdgeDeck",
            targets: ["EdgeDeck"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EdgeDeck",
            dependencies: [],
            path: "Sources/EdgeDeck"
        ),
        .testTarget(
            name: "EdgeDeckTests",
            dependencies: ["EdgeDeck"],
            path: "Tests/EdgeDeckTests"
        )
    ]
)
