// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Models",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Models",
            targets: ["Models"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            name: "HTMLEntities",
            url: "https://github.com/Kitura/swift-html-entities.git",
            from: "3.0.0"
        ),
        .package(
            name: "BetterCodable",
            url: "https://github.com/marksands/BetterCodable.git",
            .branch("master")
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Models",
            dependencies: [
                "HTMLEntities",
                "BetterCodable"
            ]),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"],
            resources: [
                .copy("Stubs")
            ]),
    ]
)
