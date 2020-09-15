//
//  ProtonSigningRequestSession.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import Starscream

public struct ProtonESRSession: Codable, Identifiable, Hashable {
    
    public var id: String
    public var signer: Name
    public var callbackUrlString: String
    public var receiveKeyString: String
    public var receiveChannel: URL
    public var createdAt: Date
    public var updatedAt: Date
    public var requestor: Account?
    
    public static func == (lhs: ProtonESRSession, rhs: ProtonESRSession) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func getReceiveKey() -> PrivateKey? {
        return PrivateKey(receiveKeyString)
    }
    
    func getRequestKey() -> PublicKey? {
        return try? PublicKey(stringValue: id) 
    }
    
}

public struct SealedMessage: ABICodable {
    let from: PublicKey
    let nonce: UInt64
    let ciphertext: Data
    let checksum: UInt32
}

public struct ProtonESRSessionWebSocketWrapper: Hashable {
    
    let id: String
    let socket: WebSocket
    
    public static func == (lhs: ProtonESRSessionWebSocketWrapper, rhs: ProtonESRSessionWebSocketWrapper) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
