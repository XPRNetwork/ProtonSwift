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
    
    var protonESR: ProtonESR
    var sig: Signature
    var session: ProtonESRSession
    var blockNum: BlockNum?
    
    init(protonESR: ProtonESR, sig: Signature, session: ProtonESRSession, blockNum: BlockNum?) {
        self.protonESR = protonESR
        self.sig = sig
        self.session = session
        self.blockNum = blockNum
    }
    
    override func main() {
        
        super.main()
        
        guard let resolvedSigningRequest = self.protonESR.resolvedSigningRequest else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue resolving ESR"))
            return
        }
        
        guard let callback = resolvedSigningRequest.getCallback(using: [self.sig], blockNum: self.blockNum) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting callback"))
            return
        }
        
        do {
            
            guard let publicReceiveKey = try self.session.getReceiveKey()?.getPublic().stringValue else {
                self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting link_key"))
                return
            }
            
            let payloadData = try callback.getPayload(extra: ["link_key": publicReceiveKey, "link_ch": self.session.receiveChannel.absoluteString, "link_name": Proton.config?.appDisplayName ?? ""])
            
            guard var parameters = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
                self.finish(retval: nil, error: Proton.ProtonError(message: "Issue getting parameters from payload"))
                return
            }
            
            if let req = parameters["req"] as? String {
                print(try SigningRequest(req))
                parameters["req"] = req.replacingOccurrences(of: "esr:", with: protonESR.initialPrefix)
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
