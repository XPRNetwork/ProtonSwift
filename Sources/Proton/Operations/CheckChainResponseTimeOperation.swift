//
//  CheckChainResponseTimeOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//


import Foundation
import WebOperations
import EOSIO

class CheckChainResponseTimeOperation: BaseOperation {
    
    var chainUrl: String
    var path: String
    
    init(chainUrl: String, path: String) {
        self.chainUrl = chainUrl
        self.path = path
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: "\(chainUrl)\(path)") else {
            self.finish(retval: URLRepsonseTimeCheck(url: chainUrl, time: Date.distantPast.timeIntervalSinceNow * -1), error: nil)
            return
        }
        
        let start = Date()
        
        let urlRequest = URLRequest(url: url, timeoutInterval: 5.0)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            if let _ = error {
                self.finish(retval: URLRepsonseTimeCheck(url: self.chainUrl, time: Date.distantPast.timeIntervalSinceNow * -1), error: nil)
            }
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                self.finish(retval: URLRepsonseTimeCheck(url: self.chainUrl, time: Date.distantPast.timeIntervalSinceNow * -1), error: nil)
                return
            }
            
            var end = Date().timeIntervalSince(start)
            var blockDiff: BlockNum?
            
            do {
                let res = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                if let hb = res["head_block_num"] as? BlockNum, let lib = res["last_irreversible_block_num"] as? BlockNum {
                    blockDiff = hb - lib
                }
            } catch {
                print(error)
            }
            
            if let blockDiff = blockDiff, blockDiff > 350 {
                end = Date.distantPast.timeIntervalSinceNow * -1
            }
            
            self.finish(retval: URLRepsonseTimeCheck(url: self.chainUrl, time: end), error: nil)
            
        }
        task.resume()
        
    }
    
}

struct URLRepsonseTimeCheck {
    let url: String
    let time: TimeInterval
}
