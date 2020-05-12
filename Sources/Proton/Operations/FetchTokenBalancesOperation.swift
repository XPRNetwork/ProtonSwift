//
//  FetchTokenBalancesOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

class FetchTokenBalancesOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    
    init(account: Account, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        guard let url = URL(string: chainProvider.stateHistoryUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        let req = API.V2.Hyperion.GetTokens(account.name)

        do {

            let res = try client.sendSync(req).get()

            var tokenBalances = Set<TokenBalance>()
            
            for token in res.tokens {
                
                if let tokenBalance = TokenBalance(accountId: self.account.id, contract: token.contract,
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
