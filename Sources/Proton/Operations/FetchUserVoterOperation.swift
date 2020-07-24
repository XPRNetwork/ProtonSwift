//
//  FetchUserVoterOperation.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchUserVoterOperation: BaseOperation {

    var account: Account
    var chainProvider: ChainProvider

    init(account: Account, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }

    override func main() {

        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
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

            if let result = res.rows.first {
                print(result)
//                account.base64Avatar = userInfo.avatar
//                account.userDefinedName = userInfo.name
//                account.verified = userInfo.verified
            }

            finish(retval: account, error: nil)

        } catch {
            finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.GetTableRows<VotersXPRABI>.path)\nERROR => \(error.localizedDescription)"))
        }

    }

}
