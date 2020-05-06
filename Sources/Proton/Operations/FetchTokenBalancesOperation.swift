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
    let rpcPath = "/v2/state/get_key_accounts"
    
    init(account: Account, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        let path = "\(chainProvider.stateHistoryUrl)\(rpcPath)?account=\(self.account.name)"
        
        WebServices.shared.getRequestJSON(withPath: path) { result in
            
            switch result {
            case .success(let res):
                
                var tokenBalances = Set<TokenBalance>()
                
                if let res = res as? [String: Any], let tokens = res["tokens"] as? [[String: Any]] {
                    
                    for token in tokens {
                        
                        guard let symbol = token["symbol"] as? String else { return }
                        guard let precision = token["precision"] as? UInt8 else { return }
                        guard let amount = token["amount"] as? Double else { return }
                        guard let contract = token["contract"] as? String else { return }
                        
                        if let tokenBalance = TokenBalance(accountId: self.account.id, contract: Name(contract),
                                                           amount: amount, precision: precision, symbol: symbol) {
                            
                            tokenBalances.update(with: tokenBalance)
                        }
                        
                    }
                    
                }
                
                self.finish(retval: tokenBalances, error: nil)
                
            case .failure(let error):
                self.finish(retval: nil, error: ProtonError.history("RPC => \(self.rpcPath)\nERROR => \(error.localizedDescription)"))
            }
            
        }
        
    }
    
}
