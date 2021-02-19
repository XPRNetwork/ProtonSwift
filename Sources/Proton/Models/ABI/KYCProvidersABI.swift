//
//  KYCProvidersABI.swift
//  
//
//  Created by Jacob Davis on 2/19/21.
//

import Foundation
import EOSIO

struct KYCProviderABI: ABICodable {

    let kyc_provider: Name
    let desc: String
    let url: String
    let iconurl: String
    let name: String
    let blisted: Bool

}
