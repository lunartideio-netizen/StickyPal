// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StickyPal",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "StickyPal",
            path: "Sources/StickyPal",
            linkerSettings: [
                .linkedFramework("Carbon"),
            ]
        )
    ]
)
