//
//  SwapPool.swift
//  
//
//  Created by Jacob Davis on 12/8/20.
//

import EOSIO
import Foundation

/**
SwapPool is the combination of two tokens that have liquidity in the Swap
*/
public struct SwapPool: Codable, Identifiable, Hashable {
    /// This is used as the primary key for storing the account
    public var id: String { return self.liquidityTokenSymbol.name }
    /// The combined Symbol
    public let liquidityTokenSymbol: Asset.Symbol
    /// The creator of the Pool
    public let creator: Name
    /// Memo used by contract
    public let memo: String
    /// First Asset used to create pool
    public let pool1: ExtendedAsset
    /// Second Asset used to create pool
    public let pool2: ExtendedAsset
    ///
    public let hash: Checksum256
    /// Fee's associated with this pool
    public let fee: SwapPoolFee
    
    public static let slippage: Double = 0.1
    
    /// :nodoc:
    public static func == (lhs: SwapPool, rhs: SwapPool) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public init(liquidityTokenSymbol: Asset.Symbol, creator: Name, memo: String, pool1: ExtendedAsset, pool2: ExtendedAsset, hash: Checksum256, fee: SwapPoolFee) {
        self.liquidityTokenSymbol = liquidityTokenSymbol
        self.creator = creator
        self.memo = memo
        self.pool1 = pool1
        self.pool2 = pool2
        self.hash = hash
        self.fee = fee
    }
    
    public var balanceAvailableToSwap: Bool {
        return Proton.shared.tokenBalances.first(where:
        {
            (
                $0.tokenContractId == "\(self.pool1.contract.stringValue):\(self.pool1.quantity.symbol.name)" ||
                $0.tokenContractId == "\(self.pool2.contract.stringValue):\(self.pool2.quantity.symbol.name)"
            ) && $0.amount.value > 0
        }) != nil
    }
    
    public var pool1TokenContract: TokenContract? {
        return Proton.shared.tokenContracts.first(where: { $0.id == "\(self.pool1.contract.stringValue):\(self.pool1.quantity.symbol.name)" })
    }
    
    public var pool2TokenContract: TokenContract? {
        return Proton.shared.tokenContracts.first(where: { $0.id == "\(self.pool2.contract.stringValue):\(self.pool2.quantity.symbol.name)" })
    }
    
    public var pool1TokenBalance: TokenBalance? {
        return Proton.shared.tokenBalances.first(where: { $0.tokenContractId == pool1TokenContract?.id })
    }
    
    public var pool2TokenBalance: TokenBalance? {
       return Proton.shared.tokenBalances.first(where: { $0.tokenContractId == pool2TokenContract?.id })
    }
    
    public var pool1Rate: Double {
        return self.pool1.quantity.value / self.pool2.quantity.value
    }
    
    public var pool2Rate: Double {
        return self.pool2.quantity.value / self.pool1.quantity.value
    }
    
    /**
 * XPR<>XUSDT (XPR -> XUSDT)
 *
 *                     pool1 * pool2
 *  term =  pool2  -  --------------
 *                     pool1 + swap
 *
 *  result = term - (term * fee)
 */
//export const compute_transfer = (pool1, pool2, swap, fee, precision) => {
//  fee = BN(fee).dividedBy(FEE_PRECISION * 100)
//  const term1 = BN(pool2)
//  const term2a = BN(pool1).multipliedBy(pool2)
//  const term2b = BN(pool1).plus(swap)
//  const term2 = term2a.dividedBy(term2b)
//  const term = term1.minus(term2)
//  const result = term.minus(term.multipliedBy(fee))
//  return result.toFixed(precision, BN.ROUND_DOWN)
//}

    public func compute(fromAmount amount: Double, fromSymbol: Asset.Symbol) -> Double {
        let flipped = self.pool1.quantity.symbol != fromSymbol
        let fee = Double(self.fee.exchangeFee) / 10000.0
        let term1 = !flipped ? self.pool2.quantity.value : self.pool1.quantity.value
        let term2a = !flipped ? (self.pool1.quantity.value * self.pool2.quantity.value) : (self.pool2.quantity.value * self.pool1.quantity.value)
        let term2b = !flipped ? (self.pool1.quantity.value + amount) : (self.pool2.quantity.value + amount)
        let term2 = term2a / term2b
        let term = term1 - term2
        let result = term - (term * fee)
        return result.roundTo(places: Int(!flipped ? self.pool2.quantity.symbol.precision : self.pool1.quantity.symbol.precision))
    }

    public func priceImpact(fromAmount amount: Double, toSymbol: Asset.Symbol) -> Double {
        let flipped = self.pool2.quantity.symbol != toSymbol
        let expectedAmount = amount * (!flipped ? self.pool2Rate : self.pool1Rate)
        let actualAmount = compute(fromAmount: amount, fromSymbol: !flipped ? self.pool1.quantity.symbol : self.pool2.quantity.symbol)
        return ((1.0 - (actualAmount / expectedAmount)) * 100).roundTo(places: 2)
    }
    
}

public struct SwapPoolFee: Codable {
    public let exchangeFee: UInt16
    public init(exchangeFee: UInt16) {
        self.exchangeFee = exchangeFee
    }
}
