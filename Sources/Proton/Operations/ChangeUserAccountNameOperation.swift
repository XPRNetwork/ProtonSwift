//
//  ChangeUserAccountNameOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import Foundation

class ChangeUserAccountNameOperation: AbstractOperation {
    
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
        
        var parameters: [String: Any] = [:]
        var path = ""
        
        DispatchQueue.main.sync {
            parameters = ["account": account.name.stringValue, "signature": signature, "name": userDefinedName]
            path = "\(chainProvider.updateAccountNameUrl.replacingOccurrences(of: "{{account}}", with: account.name.stringValue))"
        }
        
        guard let url = URL(string: path) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form URL for updateAccountNameUrl"))
            return
        }
        
        WebOperations.shared.request(method: WebOperations.RequestMethod.put, url: url, parameters: parameters) { result in
            switch result {
            case .success:
                self.finish(retval: nil, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: error)
            }
        }
        
    }
    
}
