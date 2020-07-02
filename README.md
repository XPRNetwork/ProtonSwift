## Description

Proton is a drop in library to handle all things ProtonChain. This includes but is not limited to accout management and storage, signing and pushing transctions, etc.

- [x] Swift 5
- [x] iOS v12+
- [x] macOS v10_15+
- [x] Mac Catalyst
- [x] Persist and manage Proton Accounts
- [x] Persist and manage private keys via keychain
- [x] Signing transactions
- [x] Handle ESR Signing requests

## Usage

The main class that you will need to interface with is `Proton` which encapsulates most all of the needed functions.

```swift
import Proton

Proton.initialize(Proton.Config()).fetchRequirements { result in
    Proton.shared.update { result in }
}
```

There is also another class `ProtonObservable` which can be used in iOSv13+

## Installation

### SPM

**Proton** is available through [Swift Package Manager](https://swift.org/package-manager/).
Add Proton as a dependency to your Package.swift. For more information, please see the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).

```swift
.package(url: "https://github.com/needly/proton-swift.git", .branch("master"))
```

### Cocoapods

Coming soon...

## Libraries Used
[EOSIO](https://github.com/greymass/swift-eosio) - Greymass   
[KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) - kishikawakatsumi   
