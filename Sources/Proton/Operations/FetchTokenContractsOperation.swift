//
//  FetchTokenContractsOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

class FetchTokenContractsOperation: AbstractOperation {
    
    var chainProvider: ChainProvider
    var tokenContracts: Set<TokenContract>
    
    init(chainProvider: ChainProvider, tokenContracts: Set<TokenContract>) {
        self.chainProvider = chainProvider
        self.tokenContracts = tokenContracts
    }
    
    override func main() {
        
        guard let url = URL(string: self.chainProvider.chainUrl) else {
            self.finish(retval: nil, error: WebServiceError.error("ERROR: Missing url for get table rows"))
            return
        }

        let client = Client(address: url)
        let req = API.V1.Chain.GetTableRows<TokenContractABI>(code: Name(stringValue: chainProvider.tokensTableCode),
                                                      table: Name(stringValue: "tokens"),
                                                      scope: chainProvider.tokensTableScope)

        do {

            let res = try client.sendSync(req).get()
            
            for row in res.rows {
                
                if var tokenContract = self.tokenContracts.first(where: { $0.contract.stringValue == row.tcontract.stringValue && $0.symbol.name == row.symbol.name }) {
                    
                    tokenContract.name = row.tname
                    tokenContract.url = row.url
                    tokenContract.description = row.desc
                    tokenContract.iconUrl = row.iconurl
                    tokenContract.blacklisted = row.blisted
                    
                    self.tokenContracts.update(with: tokenContract)
                    
                } else {
                    
                    let tokenContract = TokenContract(chainId: self.chainProvider.chainId, contract: row.tcontract,
                                                      issuer: row.tcontract, resourceToken: false, systemToken: false,
                                                      name: row.tname, description: row.desc, iconUrl: row.iconurl,
                                                      supply: Asset(0.0, row.symbol), maxSupply: Asset(0.0, row.symbol),
                                                      symbol: row.symbol, url: row.url, blacklisted: row.blisted)
                    
                    print(tokenContract.description)
                    
                    self.tokenContracts.update(with: tokenContract)
                    
                }
                
            }

            self.finish(retval: self.tokenContracts, error: nil)

        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: error)
        }
        
    }
    
}
