//
//  FetchChainInfoOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchChainInfoOperation: BaseOperation {
    
    var chainProvider: ChainProvider
    
    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }
        
        do {
            let client = Client(address: url)
            let info = try client.sendSync(API.V1.Chain.GetInfo()).get()
            self.finish(retval: info, error: nil)
        } catch {
            self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }
        
    }
    
}
