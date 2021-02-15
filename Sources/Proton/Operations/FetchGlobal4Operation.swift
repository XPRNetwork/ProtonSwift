//
//  FetchGlobal4Operation.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchGlobal4Operation: BaseOperation {

    var chainProvider: ChainProvider

    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }

    override func main() {

        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form chainProvider URL"))
            return
        }

        let client = Client(address: url)
        let req = API.V1.Chain.GetTableRows<Global4ABI>(code: Name(stringValue: "eosio"),
                                                           table: Name(stringValue: "global4"),
                                                           scope: Name(stringValue: "eosio"))

        do {

            let res = try client.sendSync(req).get()
            if let global4ABI = res.rows.first {
                finish(retval: Global4(global4ABI: global4ABI), error: nil)
            } else {
                throw Proton.ProtonError(message: "Unable to decode Global4ABI")
            }
            
        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}
