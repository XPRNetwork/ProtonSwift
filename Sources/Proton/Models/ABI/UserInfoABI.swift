//
//  UserInfoABI.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

struct UserInfoABI: ABICodable {
    
    struct acct: ABICodable {
        let field_0: Name
        let field_1: Name
    }

    struct ac: ABICodable {
        let field_0: Name
        let field_1: String
    }
    
    struct kyc_prov: ABICodable {
        let kyc_provider: Name
        let kyc_level: String
        let kyc_date: UInt64
    }

    let acc: Name
    let name: String
    let avatar: String
    let verified: Bool
    let verifiedon: UInt64
    let verifier: Name
    let date: UInt64
    let raccs: [Name]
    let accts: [acct]
    let ac: [ac]
    let kyc: [kyc_prov]

}
