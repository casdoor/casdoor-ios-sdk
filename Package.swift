// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Casdoor",
    platforms: [
           .macOS(.v10_15),
           .iOS(.v13),
           .tvOS(.v13),
           .watchOS(.v6)
       ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Casdoor",
            targets: ["Casdoor"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.8.1"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "CURLParser"),
        .target(
            name: "Casdoor",
            dependencies: [
                .target(name: "CURLParser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "JWTKit", package: "jwt-kit")
            ]),
        .testTarget(
            name: "CasdoorTests",
            dependencies: ["Casdoor"]),
    ]
)
