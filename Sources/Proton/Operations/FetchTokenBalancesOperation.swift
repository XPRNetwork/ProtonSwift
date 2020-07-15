//
//  FetchTokenBalancesOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchTokenBalancesOperation: BaseOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    
    init(account: Account, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.hyperionHistoryUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        let req = API.V2.Hyperion.GetTokens(account.name)

        do {

            let res = try client.sendSync(req).get()

            var tokenBalances = Set<TokenBalance>()
            
            for token in res.tokens {
                
                if let tokenBalance = TokenBalance(account: self.account, contract: token.contract,
                                                   amount: token.amount, precision: token.precision, symbol: token.symbol) {
                    tokenBalances.update(with: tokenBalance)
                }
                
            }

            finish(retval: tokenBalances, error: nil)

        } catch {
            finish(retval: nil, error: ProtonError.chain("RPC => \(API.V2.Hyperion.GetTokens.path)\nERROR => \(error.localizedDescription)"))
        }

    }
    
}
