//
//  PushTransactionOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import EOSIO
import Foundation

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
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }
        
        do {
            
            let client = Client(address: url)
            
            let req = API.V1.Chain.PushTransaction(self.signedTransaction)
            let res = try client.sendSync(req).get()
            
            self.finish(retval: res, error: nil)
            
        } catch {
            self.finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.PushTransaction.path)\nERROR => \(error.localizedDescription)"))
        }
        
    }
    
}
