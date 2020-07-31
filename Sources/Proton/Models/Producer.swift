//
//  Producer.swift
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
A Producer is basically an Account object, but with some extra info.
*/
public struct Producer: Codable, Identifiable, Hashable, ChainProviderProtocol, AvatarProtocol {
    /// This is used as the primary key for storing the contact
    public var id: String { return self.name.stringValue }
    /// The chainId associated with the account
    public var chainId: String
    /// The Name of the account. You can get the string value via name.stringValue
    public var name: Name
    /// Is the account KYC verified
    public var verified: Bool
    /// The user defined name
    public var userDefinedName: String
    /// The user modified Avatar string
    public var base64Avatar: String
    /// Whether or no the producer is active
    public var isActive: Bool
    /// Total votes accumulated by producer
    public var totalVotes: Float64
    /// The url string which makes up base url for fetching bp.json,chains.json
    public var url: String
    /// The meta info returned by bp.json
    public var org: ProducerOrg?
    /// :nodoc:
    public init(chainId: String, name: String, verified: Bool = false,
                userDefinedName: String = "", base64Avatar: String = "", isActive: Bool, totalVotes: Float64, url: String) {
        
        self.chainId = chainId
        self.name = Name(name)
        self.verified = verified
        self.userDefinedName = userDefinedName
        self.base64Avatar = base64Avatar
        self.isActive = isActive
        self.totalVotes = totalVotes
        self.url = url
        
    }
    /// :nodoc:
    public static func == (lhs: Producer, rhs: Producer) -> Bool {
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
    /// Return name if not empty, else use the account name
    public var userDefinedNameOrName: String {
        return userDefinedName.isEmpty == false ? userDefinedName : self.name.stringValue
    }

}

/**
A BPJson object containing org
*/
struct BPJson: Codable {
    /// The org property from bp.json
    public var org: ProducerOrg
}
/**
A ProducerOrg is extra info associated with Producer
*/
public struct ProducerOrg: Codable {
    /// The display name for producer
    public var candidateName: String
    /// The website url for producer
    public var website: String
    /// The ownership disclosure url
    public var ownershipDisclosure: String
    /// The code of contact url
    public var codeOfConduct: String
    /// The email for the producer
    public var email: String
    /// Branding info
    public var branding: ProducerOrgBranding
    /// Location info
    public var location: ProducerOrgLocation
}

/**
A ProducerOrgBranding is extra info associated with Producer
*/
public struct ProducerOrgBranding: Codable {
    /// The 256x256 logo url
    public var logo256: String
    /// The 1024x1024 logo url
    public var logo1024: String
    /// The svg logo url
    public var logoSvg: String
}

/**
A ProducerOrgLocation is extra info associated with Producer
*/
public struct ProducerOrgLocation: Codable {
    /// Location name
    public var name: String
    /// Country code
    public var country: String
}
