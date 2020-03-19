//
//  ChainProvider.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

struct ChainProvider: Codable, Identifiable, Hashable {
    
    let chainId: String
    let chainUrl: String
    let stateHistoryUrl: String
    let iconUrl: String
    let name: String
    let usersInfoTableCode: String
    let usersInfoTableScope: String
    
    var id: String { return chainId }
    
}
