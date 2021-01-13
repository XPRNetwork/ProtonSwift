//
//  FetchChainProviderOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import WebOperations

class FetchChainProviderOperation: BaseOperation {
    
    override func main() {
        
        super.main()
        
        guard let baseUrl = Proton.config?.baseUrl else {
            fatalError("⚛️ PROTON ERROR: BaseUrl must be valid")
        }
        
        guard let url = URL(string: "\(baseUrl)/v1/chain/info") else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form proper url chainProviders endpoint"))
            return
        }

        WebOperations.shared.request(url: url, errorModel: ProtonServiceError.self) { (result: Result<Data?, WebError>) in

            switch result {
            case .success(let data):
                
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            
                            let chainId = json["chainId"] as? String ?? ""
                            let iconUrl = json["iconUrl"] as? String ?? ""
                            let name = json["name"] as? String ?? ""
                            let systemTokenSymbol = json["systemTokenSymbol"] as? String ?? ""
                            let systemTokenContract = json["systemTokenContract"] as? String ?? ""
                            let isTestnet = json["isTestnet"] as? Bool ?? false
                            let updateAccountAvatarPath = json["updateAccountAvatarPath"] as? String ?? ""
                            let updateAccountNamePath = json["updateAccountNamePath"] as? String ?? ""
                            let exchangeRatePath = json["exchangeRatePath"] as? String ?? ""
                            let explorerUrl = json["explorerUrl"] as? String ?? ""
                            let chainUrls = json["chainUrls"] as? [String] ?? []
                            let hyperionHistoryUrls = json["hyperionHistoryUrls"] as? [String] ?? []
                            
                            let chainProvider = ChainProvider(chainId: chainId, iconUrl: iconUrl, name: name, systemTokenSymbol: systemTokenSymbol, systemTokenContract: systemTokenContract, isTestnet: isTestnet, updateAccountAvatarPath: updateAccountAvatarPath, updateAccountNamePath: updateAccountNamePath, exchangeRatePath: exchangeRatePath, explorerUrl: explorerUrl, chainUrls: chainUrls, hyperionHistoryUrls: hyperionHistoryUrls)
                            
                            self.finish(retval: chainProvider, error: nil)

                        } else {
                            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to decode ChainProvider Data"))
                        }
                    } catch {
                        self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
                    }
                } else {
                    self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to decode ChainProvider Data"))
                }

            case .failure:
                self.finish(retval: nil, error: Proton.ProtonError(message: "There was an issue fetching chainProviders config object"))
            }
            
        }
        
    }
    
}

