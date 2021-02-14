//
//  SwapPool.swift
//  
//
//  Created by Jacob Davis on 12/8/20.
//

import EOSIO
import Foundation
import BigNumber

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
    
    public let active: Bool
    
    public let reserved: UInt16
    
    public static let slippage: Double = 0.01
    
    /// :nodoc:
    public static func == (lhs: SwapPool, rhs: SwapPool) -> Bool {
        lhs.id == rhs.id
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    public init(liquidityTokenSymbol: Asset.Symbol, creator: Name, memo: String, pool1: ExtendedAsset, pool2: ExtendedAsset, hash: Checksum256, fee: SwapPoolFee, active: Bool, reserved: UInt16) {
        self.liquidityTokenSymbol = liquidityTokenSymbol
        self.creator = creator
        self.memo = memo
        self.pool1 = pool1
        self.pool2 = pool2
        self.hash = hash
        self.fee = fee
        self.active = active
        self.reserved = reserved
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
    
    public func contains(tokenContract: TokenContract?) -> Bool {
        if let tokenContract = tokenContract {
            return tokenContract == pool1TokenContract || tokenContract == pool2TokenContract
        }
        return false
    }
    
    public func opposingTokenContract(fromOther tokenContract: TokenContract?) -> TokenContract? {
        if let tokenContract = tokenContract {
            if tokenContract == pool1TokenContract {
                return pool2TokenContract
            } else if tokenContract == pool2TokenContract {
                return pool1TokenContract
            }
        }
        return nil
    }

    public func toAmount(fromAmount amount: Double, fromSymbol: Asset.Symbol) -> Double {
        
        let amount = BInt(Asset(amount, fromSymbol).units)
        let flipped = self.pool1.quantity.symbol != fromSymbol
        let precision = Int(!flipped ? self.pool2.quantity.symbol.precision : self.pool1.quantity.symbol.precision)
        let fee = BDouble(Double(self.fee.exchangeFee) / 10000.0)
        let pool1 = BInt(self.pool1.quantity.units)
        let pool2 = BInt(self.pool2.quantity.units)
        
        let term1 = !flipped ? pool2 : pool1
        let term2a = pool1 * pool2
        let term2b = !flipped ? (pool1 + amount) : (pool2 + amount)
        let term2 = BInt(Double(term2a / term2b).rounded(withPrecision: 6))
        let term = BDouble(term1 - term2)
        let result = term - (term * fee)
        let resultDouble = Double((result / pow(10, precision)).decimalExpansion(precisionAfterDecimalPoint: precision, rounded: false)) ?? 0.0
        
        return resultDouble

    }

    public func priceImpact(fromAmount amount: Double, toSymbol: Asset.Symbol) -> Double {
        let flipped = self.pool2.quantity.symbol != toSymbol
        let expectedAmount = amount * (!flipped ? self.pool2Rate : self.pool1Rate)
        let actualAmount = toAmount(fromAmount: amount, fromSymbol: !flipped ? self.pool1.quantity.symbol : self.pool2.quantity.symbol)
        return ((1.0 - (actualAmount / expectedAmount)) * 100).rounded(withPrecision: 2)
    }
    
    public func minimumReceived(toAmount amount: Double, toSymbol: Asset.Symbol) -> Double {
        let flipped = self.pool2.quantity.symbol != toSymbol
        return (amount - (amount * SwapPool.slippage)).rounded(withPrecision: Int(!flipped ? self.pool2.quantity.symbol.precision : self.pool1.quantity.symbol.precision))
    }
    
}

public struct SwapPoolFee: Codable {
    public let exchangeFee: UInt64
    public init(exchangeFee: UInt64) {
        self.exchangeFee = exchangeFee
    }
}
