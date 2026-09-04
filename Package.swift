// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Perch",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Perch", targets: ["Perch"])
    ],
    dependencies: [
        .package(url: "https://github.com/Lakr233/SkyLightWindow", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Perch",
            dependencies: [
                .product(name: "SkyLightWindow", package: "SkyLightWindow")
            ],
            path: "Sources/Perch"
        )
    ]
)
