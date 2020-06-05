//
//  TokenContract.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation
/**
The TokenContract object provides chain information about a token contract from the Proton chain
*/
public struct TokenContract: Codable, Identifiable, Hashable, ChainProviderProtocol {
    /// This is used as the primary key for storing the account
    public var id: String { return "\(self.contract.stringValue):\(self.symbol.name)" }
    /// The chainId associated with the TokenBalance
    public let chainId: String
    /// The Name of the contract. You can get the string value via contract.stringValue
    public var contract: Name
    /// The Name of the issuer. You can get the string value via issuer.stringValue
    public var issuer: Name
    /// Indicates whether or not this token is the resource token. ex: SYS
    public var resourceToken: Bool
    /// Indicates whether or not this token is the system token. ex: XPR
    public var systemToken: Bool
    /// The human readable name of the token registered by the token owner
    public var name: String
    /// The human readable description of the token registered by the token owner
    public var desc: String
    /// Icon url of the token registered by the token owner
    public var iconUrl: String
    /// The Asset supply of the token. See EOSIO type Asset for more info
    public var supply: Asset
    /// The Asset max supply of the token. See EOSIO type Asset for more info
    public var maxSupply: Asset
    /// The Symbol of the token. See EOSIO type Asset.Symbol for more info
    public var symbol: Asset.Symbol
    /// The url to the homepage of the token registered by the token owner
    public var url: String
    /// Is the token blacklisted. This is a value set by the blockproducers
    public var isBlacklisted: Bool
    /// :nodoc:
    public init(chainId: String, contract: Name, issuer: Name, resourceToken: Bool,
                  systemToken: Bool, name: String, desc: String, iconUrl: String,
                  supply: Asset, maxSupply: Asset, symbol: Asset.Symbol, url: String, isBlacklisted: Bool) {
        
        self.chainId = chainId
        self.contract = contract
        self.issuer = issuer
        self.resourceToken = resourceToken
        self.systemToken = systemToken
        self.name = name
        self.desc = desc
        self.iconUrl = iconUrl
        self.supply = supply
        self.maxSupply = maxSupply
        self.symbol = symbol
        self.url = url
        self.isBlacklisted = isBlacklisted
        
    }
    /// :nodoc:
    public static func == (lhs: TokenContract, rhs: TokenContract) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    /// ChainProvider associated with the Account
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProvider?.chainId == self.chainId ? Proton.shared.chainProvider : nil
    }
    /// :nodoc:
    public static var testObject: TokenContract {
        return TokenContract(chainId: "71ee83bcf52142d61019d95f9cc5427ba6a0d7ff8accd9e2088ae2abeaf3d3dd",
                             contract: Name("eosio.token"), issuer: Name("eosio.token"), resourceToken: false,
                             systemToken: true, name: "Proton", desc: "The proton token",
                             iconUrl: "https://static.protonchain.com/images/eosio-tokenXPR-testnet.png",
                             supply: try! Asset(stringValue: "179641154.1139 XPR"), maxSupply: try! Asset(stringValue: "10000000000.0000 XPR"),
                             symbol: try! Asset.Symbol(4, "XPR"), url: "https://protonchain.com", isBlacklisted: false)
    }
    
    public var usdRate: Double {
        return 0.02 // TODO:
    }
    
}
