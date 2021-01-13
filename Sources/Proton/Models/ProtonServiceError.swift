//
//  ProtonServiceError.swift
//  Proton Wallet
//
//  Created by Jacob Davis on 8/6/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import Foundation
import WebOperations

struct ProtonServiceError: Codable, ErrorModelMessageProtocol {
    func getMessage() -> String {
        self.message
    }
    let error: String
    let message: String
}
