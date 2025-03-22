// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "InterposeKit",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
        .tvOS(.v11),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "InterposeKit",
            targets: ["InterposeKit"]
        ),
    ],
    targets: [
        .target(name: "ITKSuperBuilder"),
        .target(
            name: "InterposeKit",
            dependencies: ["ITKSuperBuilder"]
        ),
        .testTarget(
            name: "InterposeKitTests",
            dependencies: ["InterposeKit"]
        ),
    ]
)
