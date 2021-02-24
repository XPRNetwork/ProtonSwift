//
//  Extensions.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import EOSIO

// MARK: - Private Extensions

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Public Extensions

public extension Date {
    
    static func dateFromAction(timeStamp: String?, tz: Bool = true) -> Date? {
        
        guard let timeStamp = timeStamp else {
            return nil
        }
        
        // "2018-06-11T22:11:42.500"
        let dateFormatter = DateFormatter()
        if tz {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSS"
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        }
        return dateFormatter.date(from: timeStamp)
        
    }
    
}

public extension String {
    /// Returns whether or not the string has valid account name characters
    func hasAllValidPublicAccountCreationNameCharacters() -> Bool {
        let fullCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz12345").inverted as CharacterSet
        if self.rangeOfCharacter(from: fullCharacterSet) == nil {
            return true
        }
        return false
    }
    /// Returns whether or not the string is a valid account name when creating an account
    func isValidPublicAccountCreationName() -> Bool {
        let fullCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz12345").inverted as CharacterSet
        if self.rangeOfCharacter(from: fullCharacterSet) != nil {
            return false
        }
        if self.count < 4 || self.count > 12 {
            return false
        }
        return true
    }
    /// Returns whether or not the string is a valid account name
    func isValidAccountName() -> Bool {
        let fullCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz12345.").inverted as CharacterSet
        if self.rangeOfCharacter(from: fullCharacterSet) != nil {
            return false
        }
        if self.count < 3 || self.count > 12 {
            return false
        }
        if self.prefix(1) == "." || self.suffix(1) == "." {
            return false
        }
        return true
    }
    
    mutating func popESRPrefix() -> String? {

        if let firstIdx = firstIndex(of: ":") {
            
            var prefix = String(self[self.startIndex...firstIdx])
            var remainder = String(self[self.index(firstIdx, offsetBy: 1)..<self.endIndex])
            
            if remainder.hasPrefix("//") {
                prefix += "//"
                remainder = remainder.replacingOccurrences(of: "//", with: "")
            }
            
            self = remainder
            
            return prefix
            
        }
    
        return nil
        
    }
    
}

public extension Asset {
    
    func formatted(forLocale locale: Locale = Locale(identifier: "en_US"), withSymbol symbol: Bool = false, andPrecision precision: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = precision ? Int(self.symbol.precision) : 0
        formatter.maximumFractionDigits = Int(self.symbol.precision)
        let retval = formatter.string(for: self.value) ?? "0.0"
        return symbol ? "\(retval) \(self.symbol.name)" : retval
    }
    
    func formattedMinPrecision(forLocale locale: Locale = Locale(identifier: "en_US"), withSymbol symbol: Bool = false, minPrecision: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = minPrecision
        formatter.maximumFractionDigits = Int(self.symbol.precision)
        let retval = formatter.string(for: self.value) ?? "0.0"
        return symbol ? "\(retval) \(self.symbol.name)" : retval
    }
    
    func formattedAsCurrency(forLocale locale: Locale = Locale(identifier: "en_US"), withRate rate: Double = 0.0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(for: self.value * rate) ?? "$0.00"
    }
    
}

public extension Double {

    func formatted(forLocale locale: Locale = Locale(identifier: "en_US"), withPrecision precision: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        let retval = formatter.string(for: self) ?? "0.0"
        return retval
    }
    
    func rounded(withPrecision precision: Int) -> Double {
        let divisor = pow(10.0, Double(precision))
        return (self * divisor).rounded(.down) / divisor
    }

}

public extension TimeInterval {
    var milliseconds: Int {
        return Int((truncatingRemainder(dividingBy: 1)) * 1000)
    }
}

extension PrivateKey {
    
    func getSymmetricKey(_ publicKey: PublicKey, _ nonce: UInt64) throws -> Data {
        let shared = try sharedSecret(for: publicKey)
        var keyData = Data()
        withUnsafeBytes(of: nonce) {  (bfptr) in
            guard let baseAddress = bfptr.baseAddress else { return }
            keyData.append(baseAddress.assumingMemoryBound(to: UInt8.self), count: 8)
        }
        keyData.append(shared)
        return keyData.sha512Digest
    }
    
}
