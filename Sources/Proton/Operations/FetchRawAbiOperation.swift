//
//  FetchRawAbiOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

class FetchRawAbiOperation: AbstractOperation {
    
    var account: Name
    var chainProvider: ChainProvider
    
    init(account: Name, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            return
        }
        
        let client = Client(address: url)
        let req = API.V1.Chain.GetRawAbi(account)
        
        do {
            let res = try client.sendSync(req).get()
            self.finish(retval: res, error: nil)
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: error)
        }
    }
    
}
