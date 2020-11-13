//
//  CheckResponseTimeOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//


import Foundation
import WebOperations

class CheckResponseTimeOperation: BaseOperation {
    
    var chainUrl: String
    var path: String
    
    init(chainUrl: String, path: String) {
        self.chainUrl = chainUrl
        self.path = path
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: "\(chainUrl)\(path)") else {
            self.finish(retval: URLRepsonseTimeCheck(url: chainUrl, time: Date.distantPast.timeIntervalSinceNow), error: nil)
            return
        }
        
        let start = Date()
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let _ = error {
                self.finish(retval: URLRepsonseTimeCheck(url: self.chainUrl, time: Date.distantPast.timeIntervalSinceNow), error: nil)
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                self.finish(retval: URLRepsonseTimeCheck(url: self.chainUrl, time: Date.distantPast.timeIntervalSinceNow), error: nil)
                return
            }
 
            self.finish(retval: URLRepsonseTimeCheck(url: self.chainUrl, time: Date().timeIntervalSince(start)), error: nil)
            
        }
        task.resume()
        
    }
    
}

struct URLRepsonseTimeCheck {
    let url: String
    let time: TimeInterval
}
