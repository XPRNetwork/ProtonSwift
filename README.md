# Proton Swift Wallet SDK ( BETA v0.5.0 )

**Important: *This library is currently under heavy development. Please be aware that all functionality is subject to change at anytime.* **

## Description

Proton is a drop in library to handle all things ProtonChain. This includes but is not limited to accout management and storage, signing and pushing transctions, etc.

- [x] Swift 5
- [x] iOS v12+
- [x] macOS v10_15+
- [x] Mac Catalyst
- [x] Persist and manage Proton Accounts
- [x] Persist and manage private keys via keychain
- [x] Signing transactions
- [ ] Handle ESR Signing requests ( In progress )

## Usage

The main class that you will need to interface with is `Proton` which encapsulates most all of the needed functions.

```swift
import Proton

Proton.initialize(Proton.Config(environment: .testnet)).fetchRequirements { result in
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

## MIT License

Copyright (c) 2020 Proton Chain LLC, Delaware

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
