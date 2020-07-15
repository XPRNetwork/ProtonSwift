//
//  PostRemoveSessionESROperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class PostRemoveSessionESROperation: BaseOperation {
    
    var esrSession: ESRSession
    
    init(esrSession: ESRSession) {
        self.esrSession = esrSession
    }
    
    override func main() {
        
        super.main()
        
        let parameters = ["sid": self.esrSession.sid, "sa": self.esrSession.signer.stringValue]
        
        if let path = self.esrSession.rs {
            
            guard let url = URL(string: path) else {
                self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form proper url for ESR remove session"))
                return
            }
            
            WebOperations.shared.request(method: WebOperations.RequestMethod.post, url: url, parameters: parameters) { result in
                
                switch result {
                case .success:
                    self.finish(retval: nil, error: nil)
                case .failure(let error):
                    self.finish(retval: nil, error: ProtonError.esr("MESSAGE => Issue removing esr session\nESRSession => \(self.esrSession)\nERROR => \(error.localizedDescription)"))
                }
                
            }
            
        } else {
            self.finish(retval: nil, error: ProtonError.esr("MESSAGE => No remove session url found\nESRSession => \(self.esrSession)"))
        }
    
    }
    
}
