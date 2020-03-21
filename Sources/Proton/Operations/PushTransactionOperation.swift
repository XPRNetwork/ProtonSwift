//
//  PushTransactionOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

class PushTransactionOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var signedTransaction: SignedTransaction
    
    init(account: Account, chainProvider: ChainProvider, signedTransaction: SignedTransaction) {
        self.account = account
        self.chainProvider = chainProvider
        self.signedTransaction = signedTransaction
    }
    
    override func main() {
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: WebServiceError.error("ERROR: Missing url for get table rows"))
            return
        }
        
        do {
            
            let client = Client(address: url)

            let req = API.V1.Chain.PushTransaction(self.signedTransaction)
            let res = try client.sendSync(req).get()
            
            self.finish(retval: res, error: nil)
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: error)
        }
        
    }
    
}
