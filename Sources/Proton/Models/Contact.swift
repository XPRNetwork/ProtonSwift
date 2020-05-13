//
//  Contact.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

#if os(macOS)
import AppKit
#endif
import EOSIO
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

public struct Contact: Codable, Identifiable, Hashable, ChainProviderProtocol, AvatarProtocol {
    
    public var id: String { return "\(self.chainId):\(self.name.stringValue)" }
    public var chainId: String
    public var name: Name
    public var verified: Bool
    public var fullName: String
    
    var base64Avatar: String
    
    public init(chainId: String, name: String, verified: Bool = false,
                fullName: String = "", base64Avatar: String = "") {
        
        self.chainId = chainId
        self.name = Name(name)
        self.verified = verified
        self.fullName = fullName
        self.base64Avatar = base64Avatar
        
    }
    
    public static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProviders.first(where: { $0.chainId == self.chainId })
    }

    
}
