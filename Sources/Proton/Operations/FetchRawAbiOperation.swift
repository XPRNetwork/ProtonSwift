//
//  FetchRawAbiOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchRawAbiOperation: BaseOperation {
    
    var account: Name
    var chainProvider: ChainProvider
    
    init(account: Name, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }
        
        let client = Client(address: url)
        let req = API.V1.Chain.GetRawAbi(account)
        
        do {
            let res = try client.sendSync(req).get()
            self.finish(retval: res, error: nil)
        } catch {
            self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }
    }
    
}
