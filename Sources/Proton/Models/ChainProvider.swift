//
//  ChainProvider.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
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
    public let hyperionHistoryUrl: String
    /// The url to the icon image for the Proton chain. (Mainnet/Testnet)
    public let iconUrl: String
    /// The human readable name of the Proton chain. (Mainnet/Testnet)
    public let name: String
    /// The system token symbol for the chain: XPR
    public let systemTokenSymbol: String
    /// The system token contract for the chain: eosio.token
    public let systemTokenContract: String
    /// Whether or not the chainProvider is for testnet
    public let isTestnet: Bool
    /// The api url for updating the account avatar
    public let updateAccountAvatarPath: String
    /// The api url for updating the account name
    public let updateAccountNamePath: String
    /// The api url for fetching exhange rates
    public let exchangeRatePath: String
    /// The default explorer url
    public let explorerUrl: String
    /// :nodoc:
    public init(chainId: String, chainUrl: String, hyperionHistoryUrl: String,
                iconUrl: String, name: String, systemTokenSymbol: String,
                systemTokenContract: String, isTestnet: Bool, updateAccountAvatarPath: String,
                updateAccountNamePath: String, exchangeRatePath: String, explorerUrl: String) {
        
        self.chainId = chainId
        self.chainUrl = chainUrl
        self.hyperionHistoryUrl = hyperionHistoryUrl
        self.iconUrl = iconUrl
        self.name = name
        self.systemTokenSymbol = systemTokenSymbol
        self.systemTokenContract = systemTokenContract
        self.isTestnet = isTestnet
        self.updateAccountAvatarPath = updateAccountAvatarPath
        self.updateAccountNamePath = updateAccountNamePath
        self.exchangeRatePath = exchangeRatePath
        self.explorerUrl = explorerUrl
        
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
