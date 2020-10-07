//
//  ExchangeRate.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation

struct ExchangeRate: Codable {
    let contract: String
    let symbol: String
    let rates: [String: Double]
    let priceChangePercent: Double
}
