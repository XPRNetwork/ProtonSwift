//
//  FetchTokenContractCurrencyStat.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchTokenContractCurrencyStat: BaseOperation {

    var tokenContract: TokenContract
    var chainProvider: ChainProvider

    init(tokenContract: TokenContract, chainProvider: ChainProvider) {
        self.tokenContract = tokenContract
        self.chainProvider = chainProvider
    }

    override func main() {

        super.main()
        
        guard let url = URL(string: self.chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        let req = API.V1.Chain.GetTableRows<TokenContractCurrencyStatsABI>(code: self.tokenContract.contract,
                                                                           table: Name(stringValue: "stat"),
                                                                           scope: self.tokenContract.symbol.symbolCode)

        do {

            let res = try client.sendSync(req).get()

            if let currencyStat = res.rows.first {
                self.tokenContract.maxSupply = currencyStat.max_supply
                self.tokenContract.supply = currencyStat.supply
            }

            self.finish(retval: self.tokenContract, error: nil)

        } catch {
            self.finish(retval: self.tokenContract, error: nil)
        }

    }

}
