//
//  FetchTokenContractsOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchTokenContractsOperation: BaseOperation {
    
    var chainProvider: ChainProvider
    var tokenContracts: [TokenContract]
    
    init(chainProvider: ChainProvider, tokenContracts: [TokenContract]) {
        self.chainProvider = chainProvider
        self.tokenContracts = tokenContracts
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: self.chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }
        
        func makeRequest(lowerBound: String?) {
        
            let client = Client(address: url)
            var req = API.V1.Chain.GetTableRows<TokenContractABI>(code: Name(stringValue: "token.proton"),
                                                                  table: Name(stringValue: "tokens"),
                                                                  scope: "token.proton")
            req.limit = 250
            req.lowerBound = lowerBound
        
            do {
                
                let res = try client.sendSync(req).get()
                let rows = lowerBound == nil ? res.rows : Array(res.rows.dropFirst())

                for row in rows {
                    
                    let systemToken = row.tcontract.stringValue == "eosio.token" && row.symbol.name == "XPR"
                    
                    if let tokenContractIndex = self.tokenContracts.firstIndex(where: { $0.id == "\(row.tcontract.stringValue):\(row.symbol.name)" }) {
                        
                        var tokenContract = self.tokenContracts[tokenContractIndex]
                        
                        tokenContract.name = row.tname
                        tokenContract.url = row.url
                        tokenContract.desc = row.desc
                        tokenContract.iconUrl = row.iconurl
                        tokenContract.isBlacklisted = row.blisted
                        tokenContract.systemToken = systemToken
                        
                        self.tokenContracts[tokenContractIndex] = tokenContract
                        
                    } else {
                        
                        let tokenContract = TokenContract(chainId: self.chainProvider.chainId, contract: row.tcontract,
                                                          issuer: row.tcontract, resourceToken: false, systemToken: systemToken,
                                                          name: row.tname, desc: row.desc, iconUrl: row.iconurl,
                                                          supply: Asset(0.0, row.symbol), maxSupply: Asset(0.0, row.symbol),
                                                          symbol: row.symbol, url: row.url, isBlacklisted: row.blisted)
                        
                        self.tokenContracts.append(tokenContract)
                        
                    }
                    
                }

                if res.more {
                    makeRequest(lowerBound: String(rows.last?.id ?? 0))
                } else {
                    self.finish(retval: self.tokenContracts, error: nil)
                }

            } catch {
                self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
            }
            
        }
        
        makeRequest(lowerBound: nil)
        
    }
    
}
