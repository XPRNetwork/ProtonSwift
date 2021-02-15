//
//  FetchUserRefundsXPROperation.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchUserRefundsXPROperation: BaseOperation {

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
        var req = API.V1.Chain.GetTableRows<RefundsXPRABI>(code: Name(stringValue: "eosio"),
                                                           table: Name(stringValue: "refundsxpr"),
                                                           scope: account.name)
        req.lowerBound = account.name.stringValue
        req.upperBound = account.name.stringValue

        do {

            let res = try client.sendSync(req).get()
            if let refundsXPRABI = res.rows.first {
                finish(retval: StakingRefund(quantity: refundsXPRABI.quantity, requestTime: refundsXPRABI.request_time.date), error: nil)
            } else {
                throw Proton.ProtonError(message: "Unable to decode RefundsXPRABI")
            }

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}
