// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DBManager",
    platforms: [
            .iOS(.v14),
            .tvOS(.v14),
            .watchOS(.v6),
            .macOS(.v11)
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DBManager",
            targets: ["DBManager"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Swift-YapDatabase", url: "https://github.com/mickeyl/SwiftYapDatabase.git", .branch("master")),
        .package(name: "Models", path: "../Models"),
        .package(name: "Networking", path: "../Networking")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DBManager",
            dependencies: [
                "Models",
                "Networking",
                .product(name: "YapDatabase", package: "Swift-YapDatabase"),
                .product(name: "SwiftYapDatabase", package: "Swift-YapDatabase")
            ],
            swiftSettings: [
                
            ]),
        .testTarget(
            name: "DBManagerTests",
            dependencies: ["DBManager"]),
    ]
)
