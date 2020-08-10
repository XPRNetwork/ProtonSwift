//
//  PushTransactionOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class PushTransactionOperation: BaseOperation {
    
    var chainProvider: ChainProvider
    var signedTransaction: SignedTransaction
    
    init(chainProvider: ChainProvider, signedTransaction: SignedTransaction) {
        self.chainProvider = chainProvider
        self.signedTransaction = signedTransaction
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }
        
        do {
            
            let client = Client(address: url)
            
            let req = API.V1.Chain.PushTransaction(self.signedTransaction)
            let res = try client.sendSync(req).get()
            
            self.finish(retval: res, error: nil)
            
        } catch {
            self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }
        
    }
    
}
