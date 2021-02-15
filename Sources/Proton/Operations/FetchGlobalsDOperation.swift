//
//  FetchGlobalsDOperation.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchGlobalsDOperation: BaseOperation {

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
        let req = API.V1.Chain.GetTableRows<GlobalsDABI>(code: Name(stringValue: "eosio"),
                                                         table: Name(stringValue: "globalsd"),
                                                         scope: Name(stringValue: "eosio"))

        do {

            let res = try client.sendSync(req).get()
            if let globalsDABI = res.rows.first {
                finish(retval: GlobalsD(globalsDABI: globalsDABI), error: nil)
            } else {
                throw Proton.ProtonError(message: "Unable to decode GlobalsDABI")
            }
            
        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}
