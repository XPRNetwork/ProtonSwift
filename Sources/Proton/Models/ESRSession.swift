//
//  ESRSession.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

public struct ESRSession: Codable, Identifiable, Hashable {

    public var id: String { return "\(signer.stringValue):\(requestor.name.stringValue)" }

    public var requestor: Account
    public let signer: Name
    public let chainId: String
    public var sid: String
    public var callbackUrl: String
    public var rs: String?

    public static func == (lhs: ESRSession, rhs: ESRSession) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
