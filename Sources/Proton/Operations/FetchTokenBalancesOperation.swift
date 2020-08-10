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
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
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
            
            // Even if user has 0 balance of XPR, still create tokenbalance.
            if let xprTokenContract = chainProvider.tokenContracts.first(where: {$0.systemToken == true }) {
                if tokenBalances.first(where: { $0.tokenContractId == xprTokenContract.id }) == nil {
                    if let xprTokenBalance = TokenBalance(account: self.account, contract: xprTokenContract.contract, amount: 0.0, precision: xprTokenContract.symbol.precision, symbol: xprTokenContract.symbol.name) {
                        tokenBalances.insert(xprTokenBalance)
                    }
                    
                }
            }

            finish(retval: tokenBalances, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }
    
}
