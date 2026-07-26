// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Notch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Notch", targets: ["Notch"])
    ],
    dependencies: [
        .package(url: "https://github.com/Lakr233/SkyLightWindow", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Notch",
            dependencies: [
                .product(name: "SkyLightWindow", package: "SkyLightWindow")
            ],
            path: "Sources/Notch"
        )
    ]
)
