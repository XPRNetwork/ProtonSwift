//
//  PostBackgroundESROperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

class PostBackgroundESROperation: AbstractOperation {
    
    var esr: Proton.ESR
    var sig: Signature
    var blockNum: BlockNum?
    
    init(esr: Proton.ESR, sig: Signature, blockNum: BlockNum?) {
        self.esr = esr
        self.sig = sig
        self.blockNum = blockNum
    }
    
    override func main() {
        
        guard let resolved = self.esr.resolved else { self.finish(retval: nil, error: nil); return }
        guard let callback = resolved.getCallback(using: [self.sig], blockNum: self.blockNum) else { self.finish(retval: nil, error: nil); return }
        
        do {
            
            let payloadData = try callback.getPayload(extra: ["sid": self.esr.sid])
            
            guard let parameters = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else { self.finish(retval: nil, error: nil); return }
            
            print(parameters)
            
            WebServices.shared.postRequestData(withPath: callback.url, parameters: parameters) { result in
                
                switch result {
                case .success:
                    self.finish(retval: nil, error: nil)
                case .failure(let error):
                    print("ERROR: \(error.localizedDescription)")
                    self.finish(retval: nil, error: WebServiceError.error("Error posting to esr callback: \(error.localizedDescription)"))
                }
                
            }
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: WebServiceError.error("Error posting to esr callback: \(error.localizedDescription)"))
        }
        
    }
    
}
