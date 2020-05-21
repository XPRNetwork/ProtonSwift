![Swift](https://github.com/needly/proton-swift/workflows/Swift/badge.svg?event=push)

## Description

Proton is a drop in library to handle all things ProtonChain. This includes but is not limited to account creation and management. Signing and pushing transctions, etc.

- [x] Swift 5
- [x] iOS v12+
- [x] macOS v10_15+
- [x] Persist and manage Proton Accounts
- [x] Persist and manage private keys via keychain
- [x] Signing transactions
- [x] Handle ESR Signing requests

## Usage

The main and only class that you will need to interface with is `Proton` which encapsulates all of the needed functions.

```swift
let config = Proton.Config(chainProvidersUrl: "https://e8245mepe3.execute-api.us-west-2.amazonaws.com/dev/chain-providers")

Proton.initialize(config).fetchRequirements { result in
    Proton.shared.update { result in }
}
```

Theres also another class `ProtonObservable` which can be used in iOSv13+, but that can be left for another day.

## Installation

**Proton** is available through [Swift Package Manager](https://swift.org/package-manager/).
Add Proton as a dependency to your Package.swift. For more information, please see the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).

```swift
.package(url: "https://github.com/needly/proton-swift.git", .branch("master"))
```

## Libraries Used
[EOSIO](https://github.com/greymass/swift-eosio) - Greymass   
[KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) - kishikawakatsumi   
