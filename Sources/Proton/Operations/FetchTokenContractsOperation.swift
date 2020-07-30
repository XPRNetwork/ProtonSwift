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
            self.finish(retval: nil, error: ProtonError.error("Missing chainProvider url"))
            return
        }
        
        let client = Client(address: url)
        let req = API.V1.Chain.GetTableRows<TokenContractABI>(code: Name(stringValue: "token.proton"),
                                                              table: Name(stringValue: "tokens"),
                                                              scope: "token.proton")
        
        do {
            
            let res = try client.sendSync(req).get()
            
            for row in res.rows {
                
                if let tokenContractIndex = self.tokenContracts.firstIndex(where: { $0.contract.stringValue == row.tcontract.stringValue
                        && $0.symbol.name == row.symbol.name && $0.chainId == self.chainProvider.chainId
                }) {
                    
                    var tokenContract = self.tokenContracts[tokenContractIndex]
                    
                    tokenContract.name = row.tname
                    tokenContract.url = row.url
                    tokenContract.desc = row.desc
                    tokenContract.iconUrl = row.iconurl
                    tokenContract.isBlacklisted = row.blisted
                    
                    if row.tcontract.stringValue == "eosio.token" && row.symbol.name == "XPR" {
                        tokenContract.systemToken = true
                    }
                    
                    self.tokenContracts[tokenContractIndex] = tokenContract
                    
                } else {
                    
                    let tokenContract = TokenContract(chainId: self.chainProvider.chainId, contract: row.tcontract,
                                                      issuer: row.tcontract, resourceToken: false, systemToken: false,
                                                      name: row.tname, desc: row.desc, iconUrl: row.iconurl,
                                                      supply: Asset(0.0, row.symbol), maxSupply: Asset(0.0, row.symbol),
                                                      symbol: row.symbol, url: row.url, isBlacklisted: row.blisted)
                    
                    self.tokenContracts.append(tokenContract)
                    
                }
                
            }
            
            self.finish(retval: self.tokenContracts, error: nil)
            
        } catch {
            self.finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.GetTableRows<TokenContractABI>.path)\nERROR => \(error.localizedDescription)"))
        }
        
    }
    
}
