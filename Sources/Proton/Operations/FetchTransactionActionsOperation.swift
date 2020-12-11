//
//  File.swift
//  
//
//  Created by Jacob Davis on 12/11/20.
//

import Foundation
import EOSIO
import WebOperations

class FetchTransactionActionsOperation: BaseOperation {
    
    var id: TransactionId
    var chainProvider: ChainProvider
    
    init(id: TransactionId, chainProvider: ChainProvider) {
        self.id = id
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.hyperionHistoryUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }

        let client = Client(address: url)

        let req = API.V2.Hyperion.GetTransaction<Data>(self.id)

        do {

            let res = try client.sendSync(req).get()
            finish(retval: res, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }
        
    }
    
}

