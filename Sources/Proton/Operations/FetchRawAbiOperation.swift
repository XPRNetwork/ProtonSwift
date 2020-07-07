//
//  FetchRawAbiOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
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
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }
        
        let client = Client(address: url)
        let req = API.V1.Chain.GetRawAbi(account)
        
        do {
            let res = try client.sendSync(req).get()
            self.finish(retval: res, error: nil)
        } catch {
            self.finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.GetRawAbi.path)\nERROR => \(error.localizedDescription)"))
        }
    }
    
}
