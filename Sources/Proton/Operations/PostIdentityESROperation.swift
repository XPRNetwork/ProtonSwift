//
//  PostIdentityESROperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

class PostIdentityESROperation: AbstractOperation {
    
    var esr: Proton.ESR
    var sig: Signature
    
    init(esr: Proton.ESR, sig: Signature) {
        self.esr = esr
        self.sig = sig
    }
    
    override func main() {
        
        guard let resolved = self.esr.resolved else { self.finish(retval: nil, error: nil); return }
        guard let callback = resolved.getCallback(using: [self.sig], blockNum: nil) else { self.finish(retval: nil, error: nil); return }
        
        do {
            
            let payloadData = try callback.getPayload(extra: ["sid": self.esr.sid])
            
            guard let parameters = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else { self.finish(retval: nil, error: nil); return }
            
            WebServices.shared.postRequestJSON(withPath: callback.url, parameters: parameters) { result in
                
                switch result {
                case .success:

                    self.finish(retval: nil, error: nil)
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                    self.finish(retval: nil, error: WebServiceError.error("Error posting to esr auth callback: \(error.localizedDescription)"))
                }
                
            }
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: WebServiceError.error("Error posting to esr auth callback: \(error.localizedDescription)"))
        }
        
    }
    
}
