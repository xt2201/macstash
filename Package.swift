// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacStash",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacStash",
            targets: ["MacStash"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacStash",
            path: "Sources/MacStash",
            resources: []
        )
    ]
)
