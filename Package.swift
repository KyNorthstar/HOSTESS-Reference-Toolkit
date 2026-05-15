// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HOSTESS Reference Toolkit",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HRT",
            targets: ["HRT"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/KyNorthstar/SHELF.git", branch: "production"),
        .package(url: "https://github.com/RougeWare/Swift-Either.git", from: "2.0.0"),
        .package(url: "https://github.com/RougeWare/Swift-SemVer.git", from: "3.0.0-Beta.5"),
        .package(url: "https://github.com/RougeWare/Swift-Concurrency-Tools.git", branch: "feature/AsyncBinding"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HRT",
            dependencies: [
                .product(name: "Either", package: "Swift-Either"),
                .product(name: "SHELF", package: "SHELF"),
                .product(name: "SemVer", package: "Swift-SemVer"),
                .product(name: "ConcurrencyTools", package: "Swift-Concurrency-Tools"),
            ]
        ),
        .testTarget(
            name: "HRTTests",
            dependencies: ["HRT"]
        ),
    ]
)
