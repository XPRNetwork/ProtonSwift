//
//  PostBackgroundESROperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class PostBackgroundESROperation: BaseOperation {
    
    var esr: ESR
    var sig: Signature
    var blockNum: BlockNum?
    
    init(esr: ESR, sig: Signature, blockNum: BlockNum?) {
        self.esr = esr
        self.sig = sig
        self.blockNum = blockNum
    }
    
    override func main() {
        
        super.main()
        
        guard let resolved = self.esr.resolved else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue resolving ESR"))
            return
        }
        guard let callback = resolved.getCallback(using: [self.sig], blockNum: self.blockNum) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting callback"))
            return
        }
        
        do {
            
            let payloadData = try callback.getPayload(extra: ["sid": self.esr.sid])
            
            guard let parameters = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
                self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting parameters from payload"))
                return
            }
            
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
            
        } catch {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue executing post callback from ESR"))
        }
        
    }
    
}
