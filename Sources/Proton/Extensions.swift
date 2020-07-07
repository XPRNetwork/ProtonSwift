//
//  Extensions.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation

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
        if self.rangeOfCharacter(from: fullCharacterSet) == nil {
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
        if self.rangeOfCharacter(from: fullCharacterSet) == nil {
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
    
}
