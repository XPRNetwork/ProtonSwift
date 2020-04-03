//
//  TokenContract.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

protocol TokenContractProtocol {
    var tokenContract: TokenContract? { get }
}

protocol TokenContractsProtocol {
    var tokenContracts: [TokenContract] { get }
}

public struct TokenContract: Codable, Identifiable, Hashable, ChainProviderProtocol {

    public var id: String { return "\(chainId):\(contract.stringValue):\(symbol.name)" }
    
    public let chainId: String
    
    public var contract: Name
    public var issuer: Name
    public var resourceToken: Bool
    public var systemToken: Bool
    public var name: String
    public var description: String
    public var iconUrl: String
    public var supply: Asset
    public var maxSupply: Asset
    public var symbol: Asset.Symbol
    public var url: String
    public var blacklisted: Bool
    
    internal init(chainId: String, contract: Name, issuer: Name, resourceToken: Bool,
                  systemToken: Bool, name: String, description: String, iconUrl: String,
                  supply: Asset, maxSupply: Asset, symbol: Asset.Symbol, url: String, blacklisted: Bool) {
        
        self.chainId = chainId
        self.contract = contract
        self.issuer = issuer
        self.resourceToken = resourceToken
        self.systemToken = systemToken
        self.name = name
        self.description = description
        self.iconUrl = iconUrl
        self.supply = supply
        self.maxSupply = maxSupply
        self.symbol = symbol
        self.url = url
        self.blacklisted = blacklisted
        
    }
    
    public static func == (lhs: TokenContract, rhs: TokenContract) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProviders.first(where: { $0.chainId == self.chainId })
    }
    
}
