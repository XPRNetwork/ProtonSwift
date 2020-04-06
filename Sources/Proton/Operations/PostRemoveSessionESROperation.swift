//
//  PostRemoveSessionESROperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

class PostRemoveSessionESROperation: AbstractOperation {
    
    var esrSession: ESRSession
    
    init(esrSession: ESRSession) {
        self.esrSession = esrSession
    }
    
    override func main() {
        
        let parameters = ["sid": self.esrSession.sid, "sa": self.esrSession.signer.stringValue]
        
        if let path = self.esrSession.rs {
            
            WebServices.shared.postRequestJSON(withPath: path, parameters: parameters) { result in
                
                switch result {
                case .success:
                    self.finish(retval: nil, error: nil)
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                    self.finish(retval: nil, error: WebServiceError.error("Error posting to esr reauth callback: \(error.localizedDescription)"))
                }
                
            }
            
        } else {
            self.finish(retval: nil, error: WebServiceError.error("No remove session url found"))
        }
    
    }
    
}
