//
//  ChangeUserAccountNameOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import WebOperations

class ChangeUserAccountNameOperation: BaseOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var signature: String
    var userDefinedName: String
    
    init(account: Account, chainProvider: ChainProvider, signature: String, userDefinedName: String) {
        self.account = account
        self.signature = signature
        self.chainProvider = chainProvider
        self.userDefinedName = userDefinedName
    }
    
    override func main() {
        
        super.main()
        
        var parameters: [String: Any] = [:]
        var path = ""
        
        guard let baseUrl = Proton.config?.baseUrl else {
            fatalError("⚛️ PROTON ERROR: BaseUrl must be valid")
        }
        
        DispatchQueue.main.sync {
            parameters = ["name": userDefinedName]
            path = "\(baseUrl)\(chainProvider.updateAccountNamePath.replacingOccurrences(of: "{{account}}", with: account.name.stringValue))"
        }
        
        guard let url = URL(string: path) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form URL for updateAccountNameUrl"))
            return
        }
        
        WebOperations.shared.request(method: WebOperations.RequestMethod.put, auth: WebOperations.Auth.bearer, authValue: signature, url: url, parameters: parameters, errorModel: ProtonServiceError.self) { result in
            switch result {
            case .success:
                self.finish(retval: nil, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: error)
            }
        }
        
    }
    
}
