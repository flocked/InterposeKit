// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "InterposeKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "InterposeKit",
            targets: ["InterposeKit"]
        ),
    ],
    targets: [
        .target(name: "_ExceptionCatcher", path: "Sources/ExceptionCatcher", publicHeadersPath: "", cSettings: [.headerSearchPath(".")]),
        .target(name: "ITKSuperBuilder"),
        .target(
            name: "InterposeKit",
            dependencies: ["ITKSuperBuilder", "_ExceptionCatcher"]
        ),
        .testTarget(
            name: "InterposeKitTests",
            dependencies: ["InterposeKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
