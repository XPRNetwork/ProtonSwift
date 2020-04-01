//
//  PostIdentityESROperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

class PostIdentityESROperation: AbstractOperation {
    
    var resolvedSigningRequest: ResolvedSigningRequest
    var signature: Signature
    var sid: String
    
    init(resolvedSigningRequest: ResolvedSigningRequest, signature: Signature, sid: String) {
        self.resolvedSigningRequest = resolvedSigningRequest
        self.signature = signature
        self.sid = sid
    }
    
    override func main() {
        
        guard let callback = resolvedSigningRequest.getCallback(using: [self.signature], blockNum: nil) else { self.finish(retval: nil, error: nil); return }
        
        do {
            
            let payloadData = try callback.getPayload(extra: ["sid": self.sid])
            
            guard let parameters = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else { self.finish(retval: nil, error: nil); return }
            
            //guard let payload = String(bytes: payloadData, encoding: .utf8) else { self.finish(retval: nil, error: nil); return }

            WebServices.shared.postRequestJSON(withPath: callback.url, parameters: parameters) { result in
                
                switch result {
                case .success(_):
                    self.finish(retval: nil, error: nil)
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                    self.finish(retval: nil, error: WebServiceError.error("Error fetching chain providers: \(error.localizedDescription)"))
                }
                
            }

        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: WebServiceError.error("Error fetching chain providers: \(error.localizedDescription)"))
        }

    }
    
}
