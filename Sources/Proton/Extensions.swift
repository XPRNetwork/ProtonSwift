//
//  Extensions.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import Foundation

extension Date {
    
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

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
