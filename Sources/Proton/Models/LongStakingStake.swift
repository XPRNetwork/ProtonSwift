//
//  LongStakingStake.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import BigNumber

public struct LongStakingStake: Codable {
    
    public let index: UInt64
    public let oracleIndex: UInt64
    public let account: Name
    public let startTime: Date
    public let staked: Asset
    public let oraclePrice: Float64
    
    public init(index: UInt64, oracleIndex: UInt64, account: Name, startTime: Date, staked: Asset, oraclePrice: Float64) {
        self.index = index
        self.oracleIndex = oracleIndex
        self.account = account
        self.startTime = startTime
        self.staked = staked
        self.oraclePrice = oraclePrice
    }
    
    init(longStakingStakeABI: LongStakingStakeABI) {
        self.index = longStakingStakeABI.index
        self.oracleIndex = longStakingStakeABI.oracle_index
        self.account = longStakingStakeABI.account
        self.startTime = longStakingStakeABI.start_time.date
        self.staked = longStakingStakeABI.staked
        self.oraclePrice = longStakingStakeABI.oracle_price
    }
    
    public func priceInSatsFormatted() -> String {
        let op = BDouble(oraclePrice.value * 100000000)
        return op.decimalExpansion(precisionAfterDecimalPoint: 4, rounded: false)
    }
    
    public func payout() -> Asset {
        
        var retval = Asset.init(0.0, Asset.Symbol(stringLiteral: "4,XPR"))
        
        guard let plan = Proton.shared.longStakingPlans.first(where: { $0.index == oracleIndex }) else {
            return retval
        }
        
        guard let oracleData = Proton.shared.oracleData.first(where: { $0.feedIndex == plan.oracleIndex }) else {
            return retval
        }
        
        guard let price = oracleData.dDouble else {
            return retval
        }
        
        let referencePrice = Double(price.value)
        
        let planMultiplier = Double(plan.multiplier)
        
        let op = Double(oraclePrice.value)
        let expectedPrice = op * (planMultiplier / 100.0)
        if referencePrice < expectedPrice {
            let payout = ((expectedPrice / referencePrice) * Double(staked.value))
            retval.value = payout
        } else {
            retval = staked
        }
        
        return retval
        
    }
    
    public func payoutFormatted(forLocale locale: Locale = Locale(identifier: "en_US"),
                                 withSymbol symbol: Bool = false, andPrecision precision: Bool = false) -> String {
        return self.payout().formatted(forLocale: locale, withSymbol: symbol, andPrecision: precision)
    }
    
    public func payoutCurrencyFormatted(forLocale locale: Locale = Locale(identifier: "en_US")) -> String {
        guard let tokenContract = Proton.shared.tokenContracts.first(where: { $0.systemToken == true }) else { return "$0.00" }
        let rate = tokenContract.getRate(forCurrencyCode: locale.currencyCode ?? "USD")
        return self.payout().formattedAsCurrency(forLocale: locale, withRate: rate)
    }
    
    public func claimDate() -> Date {
        
        guard let plan = Proton.shared.longStakingPlans.first(where: { $0.index == oracleIndex }) else {
            return Date.distantFuture
        }
        let interval: TimeInterval = TimeInterval(plan.planDays) * 86400
        return startTime.advanced(by: interval)
    }
    
    public func canClaim() -> Bool {
        return claimDate().timeIntervalSinceNow < 0
    }

}
