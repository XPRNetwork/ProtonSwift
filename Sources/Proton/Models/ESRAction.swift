//
//  ESRAction.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

public struct ESRAction: Codable, Identifiable, Hashable {

    public var id = UUID()

    public var account: Name
    public let name: Name
    public let chainId: String

    public static func == (lhs: ESRAction, rhs: ESRAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
