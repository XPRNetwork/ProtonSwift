//
//  ProtonSigningRequestAction.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct ProtonSigningRequestAction: Identifiable, Hashable {
    
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
    public let abi: ABI?

    public static func == (lhs: ProtonSigningRequestAction, rhs: ProtonSigningRequestAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
