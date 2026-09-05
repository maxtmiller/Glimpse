// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Glimpse",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Glimpse", targets: ["Glimpse"])
    ],
    dependencies: [
        .package(url: "https://github.com/Lakr233/SkyLightWindow", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Glimpse",
            dependencies: [
                .product(name: "SkyLightWindow", package: "SkyLightWindow")
            ],
            path: "Sources/Glimpse"
        ),
        .testTarget(
            name: "GlimpseTests",
            dependencies: ["Glimpse"],
            path: "Tests/GlimpseTests"
        )
    ]
)
