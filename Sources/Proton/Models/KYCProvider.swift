//
//  File.swift
//  
//
//  Created by Jacob Davis on 2/19/21.
//

import Foundation
import EOSIO

public struct KYCProvider: Codable {

    public let provider: Name
    public let desc: String
    public let url: String
    public let iconUrl: String
    public let name: String
    public let isBlackListed: Bool
    
    init(kycProviderABI: KYCProviderABI) {
        self.provider = kycProviderABI.kyc_provider
        self.desc = kycProviderABI.desc
        self.url = kycProviderABI.url
        self.iconUrl = kycProviderABI.iconurl
        self.name = kycProviderABI.name
        self.isBlackListed = kycProviderABI.blisted
    }

}
