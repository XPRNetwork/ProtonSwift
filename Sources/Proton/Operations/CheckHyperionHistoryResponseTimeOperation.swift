//
//  CheckHyperionHistoryResponseTimeOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//


import Foundation
import WebOperations
import EOSIO

class CheckHyperionHistoryResponseTimeOperation: BaseOperation {
    
    var historyUrl: String
    var path: String
    
    init(historyUrl: String, path: String) {
        self.historyUrl = historyUrl
        self.path = path
    }
    
    override func main() {
        
        super.main()
        
        var retval = ChainURLRepsonseTime(url: self.historyUrl, headBlock: 0, blockDiff: 10000, adjustedResponseTime: Date.distantPast.timeIntervalSinceNow * -1, rawResponseTime: Date.distantPast.timeIntervalSinceNow * -1)
        
        guard let url = URL(string: "\(historyUrl)\(path)") else {
            self.finish(retval: retval, error: nil)
            return
        }
        
        let start = Date()
        
        let urlRequest = URLRequest(url: url, timeoutInterval: 5.0)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            
            if let _ = error {
                self.finish(retval: retval, error: nil)
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                self.finish(retval: retval, error: nil)
                return
            }
            
            let end = Date().timeIntervalSince(start)
            var chainHeadBlock: BlockNum?
            var esHeadBlock: BlockNum?
            var blockDiff: BlockNum?
            
            do {
                
                if let res = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    if let health = res["health"] as? [[String: Any]] {
                        for service in health {
                            if let s = service["service"] as? String, let serviceData = service["service_data"] as? [String: Any] {
                                if s == "NodeosRPC" {
                                    chainHeadBlock = serviceData["head_block_num"] as? BlockNum
                                } else if s == "Elasticsearch" {
                                    esHeadBlock = serviceData["last_indexed_block"] as? BlockNum
                                }
                            }
                        }
                    }
                }

                if let chainHeadBlock = chainHeadBlock, let esHeadBlock = esHeadBlock {
                    blockDiff = chainHeadBlock - esHeadBlock
                }
                
                retval.blockDiff = blockDiff ?? 10000
                retval.headBlock = esHeadBlock ?? 0
                retval.adjustedResponseTime = end
                retval.rawResponseTime = end

            } catch {
                self.finish(retval: retval, error: nil)
                return
            }
            
            if let blockDiff = blockDiff, blockDiff > ChainURLRepsonseTime.hyperionInSyncThreshold {
                retval.adjustedResponseTime = Date.distantPast.timeIntervalSinceNow * -1
            }
            
            self.finish(retval: retval, error: nil)
            
        }
        task.resume()
        
    }
    
}
