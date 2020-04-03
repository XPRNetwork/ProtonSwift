//
//  PostReauthESROperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

class PostReauthESROperation: AbstractOperation {
    
    var esrSession: ESRSession
    
    init(esrSession: ESRSession) {
        self.esrSession = esrSession
    }
    
    override func main() {
        
        let parameters = [ "sid": self.esrSession.sid, "sa": self.esrSession.signer.stringValue ]
        
        var path = self.esrSession.callbackUrl
        if path.last == "/" { path.removeLast() }
        path += "/reauth"

        WebServices.shared.postRequestJSON(withPath: path, parameters: parameters) { result in
            
            switch result {
            case .success(_):
                self.finish(retval: nil, error: nil)
            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
                self.finish(retval: nil, error: WebServiceError.error("Error posting to esr reauth callback: \(error.localizedDescription)"))
            }
            
        }

    }
    
}
