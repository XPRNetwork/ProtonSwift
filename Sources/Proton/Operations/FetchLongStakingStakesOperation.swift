//
//  FetchLongStakingStakesOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchLongStakingStakesOperation: BaseOperation {

    var chainProvider: ChainProvider
    var account: Account

    init(chainProvider: ChainProvider, account: Account) {
        self.chainProvider = chainProvider
        self.account = account
    }

    override func main() {

        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form chainProvider URL"))
            return
        }

        let client = Client(address: url)
        var req = API.V1.Chain.GetTableRows<LongStakingStakeABI>(code: Name(stringValue: "longstaking"),
                                                                 table: Name(stringValue: "stakes"),
                                                                 scope: Name(stringValue: "longstaking"))
        
        req.limit = 250
        req.upperBound = account.name.stringValue
        req.lowerBound = account.name.stringValue
        req.keyType = .name
        req.indexPosition = .secondary

        do {

            let res = try client.sendSync(req).get()
            let retval: [LongStakingStake] = res.rows.map({ LongStakingStake(longStakingStakeABI: $0) })
            finish(retval: retval, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}

