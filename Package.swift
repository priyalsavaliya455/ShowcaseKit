// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShowcaseKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ShowcaseKit",
            targets: ["ShowcaseKit"]
        ),
    ],
    targets: [
        .target(
            name: "ShowcaseKit",
            path: "Sources/ShowcaseKit"
        ),
        .testTarget(
            name: "ShowcaseKitTests",
            dependencies: ["ShowcaseKit"],
            path: "Tests/ShowcaseKitTests"
        ),
    ]
)
