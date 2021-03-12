//
//  ExchangeRate.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation

public struct ExchangeRate: Codable {
    
    public let contract: String
    public let symbol: String
    public let rates: [Rate]
    
    public struct Rate: Codable {
        public let counterCurrency: String
        public let price: Double
        public let priceChangePercent: Double
        public let marketCap: Double
        public let volume: Double
        public let timestamp: Date
    }
    
}
