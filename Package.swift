// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonSwift",
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
        .package(url: "https://github.com/ProtonProtocol/WebOperations.git", from: "0.5.1-beta"),
        .package(url: "https://github.com/greymass/swift-eosio.git", .branch("master")),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0")
    ],
    targets: [
        .target(
            name: "Proton",
            dependencies: ["WebOperations", "EOSIO", "KeychainAccess"]),
        .testTarget(
            name: "ProtonTests",
            dependencies: ["Proton"]),
    ]
)
