//
//  FetchChainProvidersOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

class FetchChainProvidersOperation: AbstractOperation {
    
    override func main() {
        
        guard let path = Proton.config?.baseUrl else {
            fatalError("⚛️ PROTON ERROR: BaseUrl must be valid to fetch need configuration info")
        }
        
        guard let url = URL(string: "\(path)/info") else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form proper url chainProviders endpoint"))
            return
        }

        WebOperations.shared.getRequest(withURL: url) { (result: Result<ChainProvider, Error>) in

            switch result {
            case .success(let chainProvider):
                self.finish(retval: chainProvider, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching chainProviders config object\nERROR => \(error.localizedDescription)"))
            }
        }
        
    }
    
}
