//
//  FetchUserVotersXPROperation.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchUserVotersXPROperation: BaseOperation {

    var account: Account
    var chainProvider: ChainProvider

    init(account: Account, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }

    override func main() {

        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form chainProvider URL"))
            return
        }

        let client = Client(address: url)
        var req = API.V1.Chain.GetTableRows<VotersXPRABI>(code: Name(stringValue: "eosio"),
                                                         table: Name(stringValue: "votersxpr"),
                                                         scope: "eosio")
        req.lowerBound = account.name.stringValue
        req.upperBound = account.name.stringValue

        do {

            let res = try client.sendSync(req).get()
            finish(retval: res.rows.first, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}
