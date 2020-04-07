//
//  ESRAction.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

public struct ESRAction: Identifiable, Hashable {
    
    public enum ActionType {
        case transfer, custom
    }
    
    public struct BasicDisplay {
        public let actiontype: ActionType
        public let name: String
        public let secondary: String?
        public let extra: String?
        public let tokenContract: TokenContract?
    }

    public var id = UUID()

    public let account: Name
    public let name: Name
    public let chainId: String
    public let basicDisplay: BasicDisplay

    public static func == (lhs: ESRAction, rhs: ESRAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
