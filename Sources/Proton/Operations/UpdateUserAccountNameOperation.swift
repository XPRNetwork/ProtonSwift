//
//  File.swift
//  
//
//  Created by Jacob Davis on 7/1/20.
//

import Foundation

class UpdateUserAccountNameOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var signature: String
    var nickName: String
    
    init(account: Account, chainProvider: ChainProvider, signature: String, nickName: String) {
        self.account = account
        self.signature = signature
        self.chainProvider = chainProvider
        self.nickName = nickName
    }
    
    override func main() {
        
        var parameters: [String: Any] = [:]
        var path = ""
        
        DispatchQueue.main.sync {
            parameters = ["account": account.name.stringValue, "signature": signature, "name": nickName]
            path = "\(chainProvider.updateAccountAvatarUrl.replacingOccurrences(of: "{{account}}", with: account.name.stringValue))"
        }
        
        guard let url = URL(string: path) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form URL for updateAccountAvatarUrl"))
            return
        }
        
        WebOperations.shared.putRequestData(withURL: url, parameters: parameters) { result in
            switch result {
            case .success:
                self.finish(retval: nil, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: error)
            }
        }
        
    }
    
}
