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
    var actions: [Action]
    var privateKey: PrivateKey
    
    init(account: Account, chainProvider: ChainProvider, actions: [Action], privateKey: PrivateKey) {
        self.account = account
        self.chainProvider = chainProvider
        self.actions = actions
        self.privateKey = privateKey
    }
    
    override func main() {
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: WebServiceError.error("ERROR: Missing url for get table rows"))
            return
        }
        
        if actions.count == 0 {
            self.finish(retval: nil, error: WebServiceError.error("ERROR: Need 1 or more actions"))
            return
        }
        
        do {
            
            let client = Client(address: url)
            let info = try! client.sendSync(API.V1.Chain.GetInfo()).get()

            let expiration = info.headBlockTime.addingTimeInterval(60)
            let header = TransactionHeader(expiration: TimePointSec(expiration),
                                           refBlockId: info.lastIrreversibleBlockId)
            
            let transaction = Transaction(header, actions: self.actions)
            let signature = try self.privateKey.sign(transaction, using: info.chainId)
            
            let signedTransaction = SignedTransaction(transaction, signatures: [signature])
    
            let req = API.V1.Chain.PushTransaction(signedTransaction)
            let res = try! client.sendSync(req).get()
            
            self.finish(retval: res, error: nil)
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: error)
        }
        
    }
    
}
