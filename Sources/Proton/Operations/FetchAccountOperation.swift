//
//  FetchAccountOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import EOSIO
import Foundation

class FetchAccountOperation: AbstractOperation {
    
    var accountName: String
    var chainProvider: ChainProvider
    
    init(accountName: String, chainProvider: ChainProvider) {
        self.accountName = accountName
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }
        
        let client = Client(address: url)
        let req = API.V1.Chain.GetAccount(Name(stringValue: self.accountName))
        
        do {
            let res = try client.sendSync(req).get()
            self.finish(retval: res, error: nil)
        } catch {
            self.finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.GetAccount.path)\nERROR => \(error.localizedDescription)"))
        }
    }
    
}
