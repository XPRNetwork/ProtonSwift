//
//  ChainProvider.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

protocol ChainProviderProtocol {
    var chainProvider: ChainProvider? { get }
}

public struct ChainProvider: Codable, Identifiable, Hashable, TokenContractsProtocol {
    
    public var id: String { return chainId }
    
    public let chainId: String
    public let chainUrl: String
    public let stateHistoryUrl: String
    public let iconUrl: String
    public let name: String
    public let usersInfoTableCode: String
    public let usersInfoTableScope: String
    public let tokensTableCode: String
    public let tokensTableScope: String
    public let systemTokenSymbol: String
    public let systemTokenContract: String
    
    public init(chainId: String, chainUrl: String, stateHistoryUrl: String,
                iconUrl: String, name: String, usersInfoTableCode: String,
                usersInfoTableScope: String, tokensTableCode: String, tokensTableScope: String,
                systemTokenSymbol: String, systemTokenContract: String) {
        
        self.chainId = chainId
        self.chainUrl = chainUrl
        self.stateHistoryUrl = stateHistoryUrl
        self.iconUrl = iconUrl
        self.name = name
        self.usersInfoTableCode = usersInfoTableCode
        self.usersInfoTableScope = usersInfoTableScope
        self.tokensTableCode = tokensTableCode
        self.tokensTableScope = tokensTableScope
        self.systemTokenSymbol = systemTokenSymbol
        self.systemTokenContract = systemTokenContract
        
    }
    
    public static func == (lhs: ChainProvider, rhs: ChainProvider) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var tokenContracts: [TokenContract] {
        return Proton.shared.tokenContracts.filter { $0.chainId == self.chainId }
    }
    
}
