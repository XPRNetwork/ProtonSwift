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
    var tokenBalance: TokenBalance
    let limt = 100
    
    init(account: Account, tokenContract: TokenContract, chainProvider: ChainProvider,
         tokenBalance: TokenBalance) {
        
        self.account = account
        self.tokenContract = tokenContract
        self.chainProvider = chainProvider
        self.tokenBalance = tokenBalance
    }
    
    override func main() {

        let path = "\(self.chainProvider.stateHistoryUrl)/v2/history/get_actions?transfer.symbol=\(tokenContract.symbol.name)&account=\(self.account.name.stringValue)&filter=\(self.tokenContract.contract.stringValue)%3Atransfer&limit=\(self.limt)"
        
        WebServices.shared.getRequestJSON(withPath: path) { result in
            
            switch result {
            case .success(let res):
                
                var tokenTranfsers = Set<TokenTransferAction>()
                
                if let res = res as? [String: Any], let actions = res["actions"] as? [[String: Any]], actions.count > 0 {
                    
                    let jsonDecoder = JSONDecoder()
                    let jsonEncoder = JSONEncoder()
                
                    for action in actions {
                        
                        if let act = action["act"] as? [String: Any], var data = act["data"] as? [String: Any] {
                            
                            data["amount"] = nil
                            data["symbol"] = nil
                            
                            do {
                                
                                let jsonData = try jsonEncoder.encode(data, asType: "transfer", using: TransferActionABI.abi)
                                let transferActionData = try jsonDecoder.decode(TransferActionABI.self, from: jsonData)
                                
                                if let transferAction = TokenTransferAction(account: self.account, tokenBalance: self.tokenBalance,
                                                                            tokenContract: self.tokenContract, transferActionABI: transferActionData,
                                                                            dictionary: action) {
                                    
                                    tokenTranfsers.update(with: transferAction)
                                    
                                }
                                
                            } catch {
                                print("ERROR: Unable to decode action")
                                continue
                            }
                            
                        }

                    }

                }
                
                self.finish(retval: tokenTranfsers, error: nil)
                
            case .failure(let error):
                self.finish(retval: nil, error: WebServiceError.error("Error fetching token balances: \(error.localizedDescription)"))
            }
            
        }
        
    }
    
}
