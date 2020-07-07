//
//  Contact.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
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

/**
A Contact is a lightweight Account object which represents an Account that the activeAccount has interacted with via trasnfers, etc
*/
public struct Contact: Codable, Identifiable, Hashable, ChainProviderProtocol, AvatarProtocol {
    /// This is used as the primary key for storing the contact
    public var id: String { return self.name.stringValue }
    /// The chainId associated with the account
    public var chainId: String
    /// The Name of the account. You can get the string value via name.stringValue
    public var name: Name
    /// Is the account KYC verified
    public var verified: Bool
    /// The user modified name
    public var nickName: String
    /// The user modified Avatar string
    public var base64Avatar: String
    /// :nodoc:
    public init(chainId: String, name: String, verified: Bool = false,
                nickName: String = "", base64Avatar: String = "") {
        
        self.chainId = chainId
        self.name = Name(name)
        self.verified = verified
        self.nickName = nickName
        self.base64Avatar = base64Avatar
        
    }
    /// :nodoc:
    public static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    /// ChainProvider associated with the Account
    public var chainProvider: ChainProvider? {
        return Proton.shared.chainProvider?.chainId == self.chainId ? Proton.shared.chainProvider : nil
    }

}
