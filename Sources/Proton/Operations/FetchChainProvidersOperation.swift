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
        
        guard let path = Proton.config?.chainProvidersUrl else {
            fatalError("⚛️ PROTON ERROR: Must provider chainProvidersUrl in Proton config")
        }
        
        guard let url = URL(string: path) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form proper url chainProviders endpoint"))
            return
        }

        WebServices.shared.getRequest(withURL: url) { (result: Result<[String: ChainProvider], Error>) in

            switch result {
            case .success(let chainProviders):
                var retval = Set<ChainProvider>()
                for chainProvider in chainProviders {
                    retval.update(with: chainProvider.value)
                }
                self.finish(retval: retval, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching chainProviders config object\nERROR => \(error.localizedDescription)"))
            }
        }
        
    }
    
}
