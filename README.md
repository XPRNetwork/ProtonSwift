![Swift](https://github.com/needly/proton-swift/workflows/Swift/badge.svg?event=push)

## Description

Proton is a drop in library to handle all things ProtonChain. This includes but is not limited to account creation and management. Signing and pushing transctions, etc.

- [x] Swift 5
- [x] Support iOS v13+, macOS v10_15+
- [x] Persist and manage Proton Accounts
- [x] Persist and manage private keys via keychain
- [x] Signing transactions
- [ ] Handle ESR Signing requests

## Usage

The main and only class that you will need to interface with is `Proton` which encapsulates all of the needed functions.

With `Config` we can customize url to chainProvider and tokenContract objects as well as set the keychain indetifier string.

```swift
let config = Proton.Config(keyChainIdentifier: "myapp",
                           chainProvidersUrl: "https://e8245mepe3.execute-api.us-west-2.amazonaws.com/dev/chain-providers",
                           tokenContractsUrl: "https://e8245mepe3.execute-api.us-west-2.amazonaws.com/dev/token-contracts")

// Initialize Proton                           
Proton.initalize(config)

// Now Proton can be used from anywhere through the static shared property
Proton.shared
```

## Installation

**Proton** is available through [Swift Package Manager](https://swift.org/package-manager/).
Add Proton as a dependency to your Package.swift. For more information, please see the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).

```swift
.package(url: "https://github.com/needly/proton-swift.git", .branch("master"))
```

## Libraries Used
[EOSIO](https://github.com/greymass/swift-eosio) - Greymass   
[Valet](https://github.com/square/Valet) - Square   
[EasyStash](https://github.com/onmyway133/EasyStash) - onmyway133

## Author

Jacob Davis  
jacob@lynxwallet.io
