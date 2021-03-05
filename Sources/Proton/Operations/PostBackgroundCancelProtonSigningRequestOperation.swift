//
//  PostBackgroundCancelProtonSigningRequestOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class PostBackgroundCancelProtonSigningRequestOperation: BaseOperation {
    
    var protonESR: ProtonESR
    
    init(protonESR: ProtonESR) {
        self.protonESR = protonESR
    }
    
    override func main() {
        
        super.main()
        
        let signingRequest = self.protonESR.signingRequest
        
        guard let callback = signingRequest.unresolvedCallback else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting callback"))
            return
        }
        
        let parameters: [String: String] = ["rejected": "User canceled request"]
        
        guard let url = URL(string: callback.url) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form proper URL from callback"))
            return
        }
        
        WebOperations.shared.request(method: WebOperations.RequestMethod.post, url: url, parameters: parameters, errorModel: NilErrorModel.self) { result in
            
            switch result {
            case .success:
                self.finish(retval: nil, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
            }
            
        }
        
    }
    
}

