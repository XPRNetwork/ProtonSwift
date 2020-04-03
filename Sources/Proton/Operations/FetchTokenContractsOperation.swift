//
//  FetchTokenContractsOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

class FetchTokenContractsOperation: AbstractOperation {
    
    var chainProvider: ChainProvider
    var tokenContracts: [TokenContract]
    
    init(chainProvider: ChainProvider, tokenContracts: [TokenContract]) {
        self.chainProvider = chainProvider
        self.tokenContracts = tokenContracts
    }
    
    override func main() {
        
        guard let url = URL(string: self.chainProvider.chainUrl) else {
            self.finish(retval: nil, error: WebServiceError.error("ERROR: Missing url for get table rows"))
            return
        }
        
        let client = Client(address: url)
        let req = API.V1.Chain.GetTableRows<TokenContractABI>(code: Name(stringValue: self.chainProvider.tokensTableCode),
                                                              table: Name(stringValue: "tokens"),
                                                              scope: self.chainProvider.tokensTableScope)
        
        do {
            
            let res = try client.sendSync(req).get()
            
            for row in res.rows {
                
                if let tokenContractIndex = self.tokenContracts.firstIndex(where: { $0.contract.stringValue == row.tcontract.stringValue
                        && $0.symbol.name == row.symbol.name && $0.chainId == self.chainProvider.chainId
                }) {
                    
                    var tokenContract = self.tokenContracts[tokenContractIndex]
                    
                    tokenContract.name = row.tname
                    tokenContract.url = row.url
                    tokenContract.description = row.desc
                    tokenContract.iconUrl = row.iconurl
                    tokenContract.blacklisted = row.blisted
                    
                    self.tokenContracts[tokenContractIndex] = tokenContract
                    
                } else {
                    
                    let tokenContract = TokenContract(chainId: self.chainProvider.chainId, contract: row.tcontract,
                                                      issuer: row.tcontract, resourceToken: false, systemToken: false,
                                                      name: row.tname, description: row.desc, iconUrl: row.iconurl,
                                                      supply: Asset(0.0, row.symbol), maxSupply: Asset(0.0, row.symbol),
                                                      symbol: row.symbol, url: row.url, blacklisted: row.blisted)
                    
                    self.tokenContracts.append(tokenContract)
                    
                }
                
            }
            
            self.finish(retval: self.tokenContracts, error: nil)
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: error)
        }
        
    }
    
}
