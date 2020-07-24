//
//  FetchProducersOperation.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchProducersOperation: BaseOperation {

    var chainProvider: ChainProvider

    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }

    override func main() {

        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        var req = API.V1.Chain.GetTableRows<ProducerABI>(code: Name(stringValue: "eosio"),
                                                         table: Name(stringValue: "producers"),
                                                         scope: "eosio")
        req.limit = 100

        do {

            let res = try client.sendSync(req).get()
            finish(retval: res.rows, error: nil)

        } catch {
            finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.GetTableRows<ProducerABI>.path)\nERROR => \(error.localizedDescription)"))
        }

    }

}
