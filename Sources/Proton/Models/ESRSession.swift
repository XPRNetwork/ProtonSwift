//
//  ProtonSigningRequestSession.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation


public struct ProtonSigningRequestSession: Codable, Identifiable, Hashable {
    
    public var id: String
    public var signer: Name
    public var callbackUrlString: String
    public var receiveKeyString: String
    public var receiveChannel: URL
    public var requestor: Account?
    
    public static func == (lhs: ProtonSigningRequestSession, rhs: ProtonSigningRequestSession) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func getReceiveKey() -> PrivateKey? {
        return PrivateKey(receiveKeyString)
    }
    
}
