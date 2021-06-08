// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonSwift",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Proton",
            targets: ["Proton"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ProtonProtocol/WebOperations.git", .branch("master")),
        .package(url: "https://github.com/ProtonProtocol/swift-eosio.git", .branch("master")),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.1"),
        .package(url: "https://github.com/mkrd/Swift-BigInt.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Proton",
            dependencies: ["WebOperations", "EOSIO", "KeychainAccess", "Starscream", "BigNumber"]),
        .testTarget(
            name: "ProtonTests",
            dependencies: ["Proton"]),
    ]
)
