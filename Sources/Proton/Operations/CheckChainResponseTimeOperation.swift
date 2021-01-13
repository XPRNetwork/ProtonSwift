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
        
        var retval = ChainURLRepsonseTime(url: self.chainUrl, headBlock: 0, blockDiff: 0, adjustedResponseTime: Date.distantPast.timeIntervalSinceNow * -1, rawResponseTime: 0.0)
        
        guard let url = URL(string: "\(chainUrl)\(path)") else {
            self.finish(retval: retval, error: nil)
            return
        }

        let start = Date()

        let urlRequest = URLRequest(url: url, timeoutInterval: 5.0)

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

            if let _ = error {
                self.finish(retval: retval, error: nil)
            }
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                self.finish(retval: retval, error: nil)
                return
            }

            let end = Date().timeIntervalSince(start)
            var blockDiff: BlockNum?

            do {
                let res = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                if let hb = res["head_block_num"] as? BlockNum, let lib = res["last_irreversible_block_num"] as? BlockNum {
                    blockDiff = hb - lib
                    retval.blockDiff = blockDiff ?? 0
                    retval.headBlock = hb
                    retval.adjustedResponseTime = end
                    retval.rawResponseTime = end
                }
            } catch {
                print(error)
            }

            if let blockDiff = blockDiff, blockDiff > 350 {
                retval.adjustedResponseTime = Date.distantPast.timeIntervalSinceNow * -1
            }

            self.finish(retval: retval, error: nil)

        }
        task.resume()

    }
    
}

public struct ChainURLRepsonseTime: Codable, Hashable {
    public let url: String
    public var headBlock: BlockNum
    public var blockDiff: BlockNum
    public var adjustedResponseTime: TimeInterval
    public var rawResponseTime: TimeInterval
    
    public var hyperionInSync: Bool {
        return blockDiff < 30
    }
    
    public var chainInSync: Bool {
        return blockDiff < 350
    }
    
    /// :nodoc:
    public static func == (lhs: ChainURLRepsonseTime, rhs: ChainURLRepsonseTime) -> Bool {
        lhs.url == rhs.url
    }
    /// :nodoc:
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
}
