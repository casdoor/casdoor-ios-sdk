// swift-tools-version: 5.6
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
        .library(
            name: "Casdoor",
            targets: ["Casdoor"]),
    ],
    targets: [
        .target(name: "Casdoor"),
        .testTarget(
            name: "CasdoorTests",
            dependencies: ["Casdoor"]),
    ]
)
