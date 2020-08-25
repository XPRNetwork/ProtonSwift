//
//  File.swift
//  
//
//  Created by Jacob Davis on 8/25/20.
//

import EOSIO
import Foundation

struct RefundsXPRABI: ABICodable {

    let owner: Name
    let request_time: TimePointSec
    let quantity: Asset

}
