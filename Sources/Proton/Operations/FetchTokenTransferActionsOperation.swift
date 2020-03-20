//
//  FetchTokenTransferActionsOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

class FetchTokenTransferActionsOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var tokenContract: TokenContract
    let limt = 100
    
    init(account: Account, tokenContract: TokenContract, chainProvider: ChainProvider) {
        self.account = account
        self.tokenContract = tokenContract
        self.chainProvider = chainProvider
    }
    
    override func main() {

        let path = "\(self.chainProvider.stateHistoryUrl)/v2/history/get_actions?transfer.symbol=\(tokenContract.symbol)&account=\(self.account.name)&filter=\(self.tokenContract.contract)%3Atransfer&limit=\(self.limt)"
        
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
                        
                        let tokenBalance = TokenBalance(accountId: self.account.id,
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
