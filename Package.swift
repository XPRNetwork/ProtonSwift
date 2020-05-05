// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Proton",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Proton",
            targets: ["Proton"]),
    ],
    dependencies: [
        .package(url: "https://github.com/greymass/swift-eosio.git", .branch("master")),
        .package(url: "https://github.com/Square/Valet", from: "3.2.8")
    ],
    targets: [
        .target(
            name: "Proton",
            dependencies: ["EOSIO", "Valet"]),
        .testTarget(
            name: "ProtonTests",
            dependencies: ["Proton"]),
    ]
)
