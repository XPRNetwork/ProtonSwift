//
//  ChangeUserAccountAvatarOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import Foundation

#if os(OSX)
import AppKit
public typealias AvatarImage = NSImage

#else
import UIKit
public typealias AvatarImage = UIImage
#endif

class ChangeUserAccountAvatarOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var signature: String
    var image: AvatarImage
    
    init(account: Account, chainProvider: ChainProvider, signature: String, image: AvatarImage) {
        self.account = account
        self.signature = signature
        self.chainProvider = chainProvider
        self.image = image
    }
    
    override func main() {
        
        guard let imageData = self.image.jpegData(compressionQuality: 1) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => ERROR CONVERTING IMAGE TO DATA"))
            return
        }
        
        var parameters: [String: Any] = [:]
        var path = ""
        
//        DispatchQueue.main.sync {
//            parameters = ["account": account.name.stringValue, "signature": signature, "name": userDefinedName]
//            path = "\(chainProvider.updateAccountAvatarUrl.replacingOccurrences(of: "{{account}}", with: account.name.stringValue))"
//        }
////
////        guard let url = URL(string: path) else {
////            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form URL for updateAccountNameUrl"))
////            return
////        }
////
////        WebOperations.shared.putRequestData(withURL: url, parameters: parameters) { result in
////            switch result {
////            case .success:
////                self.finish(retval: nil, error: nil)
////            case .failure(let error):
////                self.finish(retval: nil, error: error)
////            }
////        }
        
    }
    
}
