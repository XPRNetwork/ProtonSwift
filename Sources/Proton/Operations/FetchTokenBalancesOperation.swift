//
//  File.swift
//  
//
//  Created by Jacob Davis on 3/19/20.
//

import Foundation

class FetchTokenBalancesOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    
    init(account: Account, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }
    
    override func main() {

        let path = "\(chainProvider.stateHistoryUrl)/v2/state/get_tokens?account=\(self.account.name)"
        
        WebServices.shared.getRequestJSON(withPath: path) { result in
            
            switch result {
            case .success(let res):
                
                var tokenBalances = Set<TokenBalance>()
                
                if let res = res as? [String: Any], let tokens = res["tokens"] as? [[String: Any]] {
                
                    for token in tokens {
                        
                        guard let symbol = token["symbol"] as? String else {
                            return
                        }
                        guard let precision = token["precision"] as? Int else {
                            return
                        }
                        guard let amount = token["amount"] as? Double else {
                            return
                        }
                        guard let contract = token["contract"] as? String else {
                            return
                        }
                        
                        let tokenBalance = TokenBalance(accountId: self.account.id, chainId: self.chainProvider.chainId,
                                                        contract: contract, symbol: symbol, precision: precision, amount: amount)
                        
                        tokenBalances.update(with: tokenBalance)
                        
                    }

                }
                
                self.finish(retval: tokenBalances, error: nil)
                
            case .failure(let error):
                self.finish(retval: nil, error: WebServiceError.error("Error fetching token balances: \(error.localizedDescription)"))
            }
            
        }
        
    }
    
}
