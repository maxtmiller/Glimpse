// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Notch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NotchWeather", targets: ["NotchWeather"])
    ],
    targets: [
        .executableTarget(
            name: "NotchWeather",
            path: "Sources/NotchWeather"
        )
    ]
)
