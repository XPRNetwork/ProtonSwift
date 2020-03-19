//
//  Account.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

public struct Account: Codable, Identifiable, Hashable {

    public var id: String { return chainId+name }
    public var chainId: String
    public var name: String
    public var verified: Bool
    public var fullName: String
    
    var base64Avatar: String
    
    public init(chainId: String, name: String, verified: Bool = false,
                fullName: String = "", base64Avatar: String = "") {
        
        self.chainId = chainId
        self.name = name
        self.verified = verified
        self.fullName = fullName
        self.base64Avatar = base64Avatar
        
    }
    
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

}
