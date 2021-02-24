//
//  FetchOracleDataOperation.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations
import BigNumber

class FetchOracleDataOperation: BaseOperation {

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
        let req = API.V1.Chain.GetTableRows<OracleDataABI>(code: Name(stringValue: "oracles"),
                                                           table: Name(stringValue: "data"),
                                                           scope: Name(stringValue: "oracles"))

        do {

            let res = try client.sendSync(req).get()            
            let retval: [OracleData] = res.rows.map({ OracleData(oracleDataABI: $0) })
            finish(retval: retval, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}

