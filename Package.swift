// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacStash",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
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
        ),
        .library(
            name: "SideDockCore",
            targets: ["SideDockCore"]
        ),
        .library(
            name: "SideDockWidgets",
            targets: ["SideDockWidgets"]
        ),
        .library(
            name: "SideDockUI",
            targets: ["SideDockUI"]
        ),
        .library(
            name: "SideDockSystem",
            targets: ["SideDockSystem"]
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
        .target(
            name: "SideDockCore",
            path: "Sources/SideDockCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SideDockWidgets",
            dependencies: [
                "SideDockCore"
            ],
            path: "Sources/SideDockWidgets",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SideDockUI",
            dependencies: [
                "MacStashCore",
                "SideDockCore",
                "SideDockWidgets"
            ],
            path: "Sources/SideDockUI",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "SideDockSystem",
            dependencies: [
                "SideDockCore",
                "SideDockWidgets",
                "SideDockUI"
            ],
            path: "Sources/SideDockSystem",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "MacStash",
            dependencies: [
                "MacStashCore",
                "SideDockCore",
                "SideDockWidgets",
                "SideDockUI",
                "SideDockSystem",
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
                "MacStashCore",
                "SideDockCore",
                "SideDockWidgets",
                "SideDockUI",
                "SideDockSystem"
            ],
            path: "Tests/MacStashTests"
        )
    ]
)
