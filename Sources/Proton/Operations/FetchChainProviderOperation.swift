//
//  FetchChainProviderOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import Foundation

class FetchChainProviderOperation: AbstractOperation {
    
    override func main() {
        
        guard let baseUrl = Proton.config?.baseUrl else {
            fatalError("⚛️ PROTON ERROR: BaseUrl must be valid")
        }
        
        guard let url = URL(string: "\(baseUrl)/v1/chain/info") else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form proper url chainProviders endpoint"))
            return
        }

        WebOperations.shared.request(url: url) { (result: Result<ChainProvider, Error>) in

            switch result {
            case .success(let chainProvider):
                self.finish(retval: chainProvider, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching chainProviders config object\nERROR => \(error.localizedDescription)"))
            }
            
        }
        
    }
    
}
