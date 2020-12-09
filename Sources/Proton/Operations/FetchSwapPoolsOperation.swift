//
//  FetchSwapPoolsOperation.swift
//  
//
//  Created by Jacob Davis on 12/8/20.
//

import EOSIO
import Foundation
import WebOperations

class FetchSwapPoolsOperation: BaseOperation {
    
    var chainProvider: ChainProvider
    
    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: self.chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }
        
        var swapPools = [SwapPool]()

        func makeRequest(lowerBound: String?) {
        
            let client = Client(address: url)
            var req = API.V1.Chain.GetTableRows<SwapPoolsABI>(code: Name(stringValue: "swaptest2"),
                                                                  table: Name(stringValue: "pools"),
                                                                  scope: "swaptest2")
            req.limit = 250
            req.lowerBound = lowerBound
        
            do {
                
                let res = try client.sendSync(req).get()
                let rows = lowerBound == nil ? res.rows : Array(res.rows.dropFirst())
                
                let pools = rows.map({
                    return SwapPool(liquidityTokenSymbol: $0.lt_symbol, creator: $0.creator, memo: $0.memo,
                                    pool1: $0.pool1, pool2: $0.pool2, hash: $0.hash, fee: SwapPoolFee(exchangeFee: $0.pool_fee.exchange_fee))
                })
                
                swapPools.append(contentsOf: pools)
                
                if res.more {
                    makeRequest(lowerBound: rows.last?.lt_symbol.stringValue)
                } else {
                    self.finish(retval: swapPools, error: nil)
                }

            } catch {
                self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
            }
            
        }
        
        makeRequest(lowerBound: nil)
        
    }
    
}
