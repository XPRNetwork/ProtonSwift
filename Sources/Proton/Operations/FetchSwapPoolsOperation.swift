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
            var req = API.V1.Chain.GetTableRows<SwapPoolsABI>(code: Name(stringValue: "proton.swaps"),
                                                                  table: Name(stringValue: "pools"),
                                                                  scope: "proton.swaps")
            req.limit = 250
            req.lowerBound = lowerBound
        
            do {
                
                let res = try client.sendSync(req).get()
                let rows = lowerBound == nil ? res.rows : Array(res.rows.dropFirst())
                
                for row in rows {
                    if row.active == true {
                        swapPools.append(
                            SwapPool(liquidityTokenSymbol: row.lt_symbol, creator: row.creator, memo: row.memo, pool1: row.pool1, pool2: row.pool2, hash: row.hash, fee: SwapPoolFee(exchangeFee: row.fee.exchange_fee), active: row.active, reserved: row.reserved)
                        )
                    }
                }
                
                if res.more {
                    makeRequest(lowerBound: rows.last?.lt_symbol.stringValue)
                } else {
                    self.finish(retval: swapPools, error: nil)
                }

            } catch {
                print(error.localizedDescription)
                self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
            }
            
        }
        
        makeRequest(lowerBound: nil)
        
    }
    
}
