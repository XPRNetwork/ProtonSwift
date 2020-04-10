//
//  UserInfoABI.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

//{
//    "name": "acc",
//    "type": "name"
//},
//{
//    "name": "name",
//    "type": "string"
//},
//{
//    "name": "avatar",
//    "type": "string"
//},
//{
//    "name": "verified",
//    "type": "bool"
//},
//{
//    "name": "date",
//    "type": "uint64"
//},
//{
//    "name": "verifiedon",
//    "type": "uint64"
//},
//{
//    "name": "verifier",
//    "type": "name"
//},
//{
//    "name": "raccs",
//    "type": "name[]"
//},
//{
//    "name": "aacts",
//    "type": "tuple_name_name[]"
//},
//{
//    "name": "ac",
//    "type": "tuple_name_string[]"
//}

struct UserInfoABI: ABICodable {
    
    struct acct: ABICodable {
        let field_0: Name
        let field_1: Name
    }

    struct ac: ABICodable {
        let field_0: Name
        let field_1: String
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

}
