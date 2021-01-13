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
    /// List of chain urls. IMPORTANT if you reoder this list, you should also reoder the chainUrlResponse List and visa versa
    public var chainUrls: [String]
    /// List of hyperion history urls. IMPORTANT if you reoder this list, you should also reoder the hyperionHistoryUrlResponses List and visa versa
    public var hyperionHistoryUrls: [String]
    /// List of chain url health checks
    public var chainUrlResponses: [ChainURLRepsonseTime]
    /// List of history url health checks
    public var hyperionHistoryUrlResponses: [ChainURLRepsonseTime]
    /// :nodoc:
    public init(chainId: String, iconUrl: String, name: String, systemTokenSymbol: String,
                systemTokenContract: String, isTestnet: Bool, updateAccountAvatarPath: String,
                updateAccountNamePath: String, exchangeRatePath: String, explorerUrl: String,
                chainUrls: [String], hyperionHistoryUrls: [String],
                chainUrlResponses: [ChainURLRepsonseTime] = [], hyperionHistoryUrlResponses: [ChainURLRepsonseTime] = []) {
        
        self.chainId = chainId
        self.iconUrl = iconUrl
        self.name = name
        self.systemTokenSymbol = systemTokenSymbol
        self.systemTokenContract = systemTokenContract
        self.isTestnet = isTestnet
        self.updateAccountAvatarPath = updateAccountAvatarPath
        self.updateAccountNamePath = updateAccountNamePath
        self.exchangeRatePath = exchangeRatePath
        self.explorerUrl = explorerUrl
        self.chainUrls = chainUrls
        self.hyperionHistoryUrls = hyperionHistoryUrls
        self.chainUrlResponses = chainUrlResponses
        self.hyperionHistoryUrlResponses = hyperionHistoryUrlResponses
        
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
    /// The base url to the public Proton chain rpc provider
    public var chainUrl: String {
        return chainUrls.first ?? ""
    }
    /// The base url to the public Proton hyperion provider
    public var hyperionHistoryUrl: String {
        return hyperionHistoryUrls.first ?? ""
    }
    
}
