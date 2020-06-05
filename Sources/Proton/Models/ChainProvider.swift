//
//  ChainProvider.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

/**
ChainProvider the object that provides chain related configuration aspects of the Proton objects
*/
public struct ChainProvider: Codable, Identifiable, Hashable, TokenContractsProtocol {
    /// Id is the chainId
    public var id: String { return chainId }
    /// The chainId associated with the ChainProvider
    public let chainId: String
    /// The base url to the public Proton chain rpc provider
    public let chainUrl: String
    /// The base url to the public Proton chain Hyperion history provider
    public let stateHistoryUrl: String
    /// The url to the icon image for the Proton chain. (Mainnet/Testnet)
    public let iconUrl: String
    /// The human readable name of the Proton chain. (Mainnet/Testnet)
    public let name: String
    /// The system token symbol for the chain: XPR
    public let systemTokenSymbol: String
    /// The system token contract for the chain: eosio.token
    public let systemTokenContract: String
    /// :nodoc:
    public init(chainId: String, chainUrl: String, stateHistoryUrl: String,
                iconUrl: String, name: String, systemTokenSymbol: String,
                systemTokenContract: String) {
        
        self.chainId = chainId
        self.chainUrl = chainUrl
        self.stateHistoryUrl = stateHistoryUrl
        self.iconUrl = iconUrl
        self.name = name
        self.systemTokenSymbol = systemTokenSymbol
        self.systemTokenContract = systemTokenContract
        
    }
    /// :nodoc:
    public static func == (lhs: ChainProvider, rhs: ChainProvider) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    /// TokenContracts associated with this chainProvider
    public var tokenContracts: [TokenContract] {
        return Proton.shared.tokenContracts.filter { $0.chainId == self.chainId }
    }
    
}
