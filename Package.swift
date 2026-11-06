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
        )
    ],
    targets: [
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
                "MacStashCore"
            ],
            path: "Sources/MacStash",
            resources: [
                .process("Resources")
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
