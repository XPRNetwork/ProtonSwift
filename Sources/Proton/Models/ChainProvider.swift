//
//  ChainProvider.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

public struct ChainProvider: Codable, Identifiable, Hashable {

    public let chainId: String
    public let chainUrl: String
    public let stateHistoryUrl: String
    public let iconUrl: String
    public let name: String
    public let usersInfoTableCode: String
    public let usersInfoTableScope: String
    
    public var id: String { return chainId }
    
    public init(chainId: String, chainUrl: String, stateHistoryUrl: String, iconUrl: String,
                name: String, usersInfoTableCode: String, usersInfoTableScope: String) {
        
        self.chainId = chainId
        self.chainUrl = chainUrl
        self.stateHistoryUrl = stateHistoryUrl
        self.iconUrl = iconUrl
        self.name = name
        self.usersInfoTableCode = usersInfoTableCode
        self.usersInfoTableScope = usersInfoTableScope
        
    }
    
}
