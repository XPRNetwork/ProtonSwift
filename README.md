# Proton Swift Wallet SDK ( BETA v0.5.0 ) 🚧

**Important:** *This library is currently under heavy development. Please be aware that all functionality is subject to change at anytime. Documention and examples are also being worked on and will be added over time as well.*

## Description

Proton is a drop in library to handle all things ProtonChain. This includes but is not limited to accout management and storage, signing and pushing transctions, etc.

- [x] Swift 5
- [x] iOS v13+
- [x] macOS v10_15+
- [x] Mac Catalyst
- [x] Persist and manage Proton Accounts
- [x] Persist and manage private keys via keychain
- [x] Signing transactions
- [x] Handle ESR Signing requests ( In progress ) 🚧


## Functional Reference

[https://protonprotocol.github.io/ProtonSwift](https://protonprotocol.github.io/ProtonSwift)

## Usage

The main class that you will need to interface with is `Proton` which encapsulates most all of the needed functions. Firstly you import `Proton`. Initialize `Proton` by passing a `Proton.Config` struct. You'll want to also call `Proton.shared.fetchRequirements` function at startup so that all needed requirements for the library will be present before moving forward.

```swift
import Proton

Proton.initialize(Proton.Config()).updateDataRequirements { result in
    Proton.shared.updateAccount { result in }
}
```

There are currently 2 environment enum values that can be used which live on the `Proton.Config` object.

```swift
public enum Environment: String {
    case testnet = "https://api-dev.protonchain.com"
    case mainnet = "https://api.protonchain.com"
}
```

As seen above, most of the function closures provided by the library will return swift's `Result` type. 

This library requires the user to authenticate via FaceId, TouchId, or phone passcode fallback when signing transactions. This is because that private key is stored in the keychain using the user presense flag.
 
You'll need to add the following to your app's Info.plist file.

```xml
<key>NSFaceIDUsageDescription</key>
<string>$(PRODUCT_NAME) Authentication with TouchId or FaceID</string>
```

### Find and Import an account

When importing and account using a private key, its important to note that sometimes a private key may have more than 1 account associated with it. For that reason we will call the `findAccounts` function to get an unattached list of `Account` structs associated with the public key that was extracted from the private key wif.

```swift
Proton.shared.findAccounts(forPrivateKey: "<wif_formatted_private_key_here>") { result in
    
    switch result {
    case .success(let accounts):
        
        if let account = accounts.first {

		Proton.shared.setAccount(withName: account.name.stringValue, andPrivateKey: Proton.PrivateKey("<wif_formatted_private_key_here>")) { result in
				    
			if case .success = result {
				print("YAH")
			} else if case .failure(let error) = result {
				 print(error.localizedDescription)
			}
				    
		}
            
        }

    case .failure(let error):
        print(error)
    }
}
```

>  The `Proton` library only stores one `Account` struct at a time. Using the `storePrivateKey` or `setAccount` functions will overwrite the the current active `Account` if there is already one. It will however NOT remove the private key from the keychain. That operation will have to be done seperately. 

Now that you have an active `Account` stored, you can access it at `Proton.shared.account`

### Update active account

You can easily fetch the latest actions and other updates about your active account by simply calling `Proton.shared.updateAccount`

```swift
Proton.shared.updateAccount { result in }
```

> This will fetch the lates `TokenTransferAction` items, `Account` info, etc. It will automatically update these on the shared `Proton` singleton.

### Transfer token

Transfering a token is a fairly simple process. You'll the need to grab the `TokenContract` struct of the token you will be transfering. This can be fetched from `Proton.shared.tokenContracts`.

```swift
guard let xprTokenContract = Proton.shared.tokenContracts.first(where: { $0.contract.stringValue == "eosio.token" && $0.symbol.name == "XPR" }) else {
    return
}
    
Proton.shared.transfer(to: Proton.Name("blah"), quantity: 1.0, tokenContract: xprTokenContract, memo: "My first transfer") { result in
    switch result {
    case .success(let transferTokenAction):
        break
    case .failure(let error):
        print(error)
    }
}
```
> Its important to note that this function will require the user to authenticate via FaceId, TouchId, or phone passcode fallback. This is because that private key is stored in the keychain using the user presense flag. Also make sure you have added the following to your Info.plist file.
> 
```xml
<key>NSFaceIDUsageDescription</key>
<string>$(PRODUCT_NAME) Authentication with TouchId or FaceID</string>
```

### Get PrivateKey from keychain

You can fetch the private key stored for an `Account` by calling the member function `privateKey(forPermissionName: String)`. You will mostly be dealing with active permission keys.

```swift
guard let account = Proton.shared.account else {
    return
}
    
guard let privateKey = account.privateKey(forPermissionName: "active") else {
    return
}
```

### Other functions to note

```swift
Proton.shared.loadAll()
```
> Used to load all saved data objects from disk. This is called during the `Proton` init phase. You may however want to call this for instance when your app goes comes back from the background.

```swift
Proton.shared.saveAll()
```
> Used to save all data objects to disk that are currently in memory on the `Proton.shared` singleton. This is called at the completion of `Proton.shared.updateAccount`. You may however want to call this for instance when your app goes in the background.

```swuft
Proton.shared.generatePrivateKey()
```
> This can be used to generate a new private key. This is useful if you want to use the Proton API to create an account as you would use this key to extract the public key's needed for account creation. FYI. The account creation API requires an API key which you will need to register for. The account creation API is heavily rate limited. If you are a wallet provider and need a more liberal rate limit you will have to contact us. 

[Functional Reference](https://protonprotocol.github.io/ProtonSwift)
> A function reference has been generated from the commented code.

### Vote for Block Producer
Coming soon...

### Stake XPR Tokens
Coming soon...

### Unstake XPR Tokens
Coming soon...

### Claim Staking Rewards
Coming soon...

### Handling ESR requests
Coming soon...

## Installation

### SPM

**Proton** is available through [Swift Package Manager](https://swift.org/package-manager/).
Add Proton as a dependency to your Package.swift. For more information, please see the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).

```swift
.package(url: "https://github.com/ProtonProtocol/ProtonSwift.git", .branch("master"))
```

### Cocoapods

Coming soon...

## Libraries Used
[WebOperations](https://github.com/ProtonProtocol/WebOperations.git) - Proton  
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
