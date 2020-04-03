//
//  UserInfoABI.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

struct UserInfoABI: ABICodable {

    let acc: Name
    let name: String
    let avatar: String
    let verified: Bool
    let date: UInt64
    let data: String
    let primary: Bool

}
