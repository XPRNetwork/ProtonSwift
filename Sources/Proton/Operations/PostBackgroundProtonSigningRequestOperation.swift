//
//  PostBackgroundProtonSigningRequestOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class PostBackgroundProtonSigningRequestOperation: BaseOperation {
    
    var protonSigningRequest: ProtonSigningRequest
    var sig: Signature
    var session: ProtonSigningRequestSession
    var blockNum: BlockNum?
    
    init(protonSigningRequest: ProtonSigningRequest, sig: Signature, session: ProtonSigningRequestSession, blockNum: BlockNum?) {
        self.protonSigningRequest = protonSigningRequest
        self.sig = sig
        self.session = session
        self.blockNum = blockNum
    }
    
    override func main() {
        
        super.main()
        
        guard let resolvedSigningRequest = self.protonSigningRequest.resolvedSigningRequest else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue resolving ESR"))
            return
        }
        
        guard let callback = resolvedSigningRequest.getCallback(using: [self.sig], blockNum: self.blockNum) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting callback"))
            return
        }
        
        do {
            
            guard let publicReceiveKey = try self.session.getReceiveKey()?.getPublic().stringValue else {
                self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting psr_receive_key"))
                return
            }
            
            let payloadData = try callback.getPayload(extra: ["psr_receive_key": publicReceiveKey, "psr_receive_channel": self.session.receiveChannel.absoluteString])
            
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
