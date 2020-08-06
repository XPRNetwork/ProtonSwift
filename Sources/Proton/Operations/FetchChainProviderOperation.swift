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
            self.finish(retval: nil, error: ProtonError.error("Unable to form proper url chainProviders endpoint"))
            return
        }

        WebOperations.shared.request(url: url, errorModel: TestERR.self) { (result: Result<ChainProvider, WebError>) in

            switch result {
            case .success(let chainProvider):
                self.finish(retval: chainProvider, error: nil)
            case .failure:
                self.finish(retval: nil, error: ProtonError.error("There was an issue fetching chainProviders config object"))
            }
            
        }
        
    }
    
}

public struct TestERR: Codable {
    let message: String
}
