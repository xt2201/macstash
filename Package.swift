// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacStash",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacStash",
            targets: ["MacStash"]
        ),
        .library(
            name: "MacStashCore",
            targets: ["MacStashCore"]
        ),
        .library(
            name: "MacStashNowPlaying",
            type: .dynamic,
            targets: ["MacStashNowPlaying"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4")
    ],
    targets: [
        .target(
            name: "MacStashNowPlaying",
            path: "Sources/MacStashNowPlaying"
        ),
        .target(
            name: "MacStashCore",
            path: "Sources/MacStashCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "MacStash",
            dependencies: [
                "MacStashCore",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/MacStash",
            exclude: [
                "Resources"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "MacStashTestRunner",
            dependencies: [
                "MacStashCore"
            ],
            path: "Tests/MacStashTests"
        )
    ]
)
