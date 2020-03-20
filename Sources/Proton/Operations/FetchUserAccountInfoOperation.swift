//
//  FetchUserAccountInfoOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation
import EOSIO

class FetchUserAccountInfoOperation: AbstractOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    
    init(account: Account, chainProvider: ChainProvider) {
        self.account = account
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        let parameters = [
            "table": "usersinfo",
            "json": true,
            "lower_bound": self.account.name,
            "upper_bound": self.account.name,
            "scope": self.chainProvider.usersInfoTableScope,
            "code": self.chainProvider.usersInfoTableCode
            ] as [String : Any]
        
        WebServices.shared.postRequestJSON(withPath: "\(chainProvider.chainUrl)/v1/chain/get_table_rows", parameters: parameters) { result in
            
            switch result {
                
            case .success(let retval):
                
                guard let retval = retval as? [String: Any] else { return self.finish(retval: nil, error: WebServiceError.error("ERROR: No rows found")) }
                guard let rows = retval["rows"] as? [[String: Any]], rows.count > 0 else { return self.finish(retval: nil, error: WebServiceError.error("ERROR: No rows found")) }
                guard let firstRow = rows.first else { return self.finish(retval: nil, error: WebServiceError.error("ERROR: No rows found")) }
                
                if let avatar = firstRow["avatar"] as? String {
                    self.account.base64Avatar = avatar
                }
                
                if let name = firstRow["name"] as? String, !name.isEmpty {
                    self.account.fullName = name
                }
                
                if let verified = firstRow["verified"] as? Bool {
                    self.account.verified = verified
                }
                
                self.finish(retval: self.account, error: nil)
                
            case .failure(let error):
                self.finish(retval: nil, error: WebServiceError.error(error.localizedDescription))
            }
            
        }

        
//        guard let url = URL(string: chainProvider.chainUrl) else {
//            self.finish(retval: nil, error: WebServiceError.error("ERROR: Missing url for get table rows"))
//            return
//        }
        
//        struct UserInfo: ABICodable {
//            let avatar: String?
//            let name: String?
//            let verified: Bool?
//        }
//
//        let client = Client(address: url)
//        var req = API.V1.Chain.GetTableRows<UserInfo>(code: Name(stringValue: chainProvider.usersInfoTableCode), table: Name(stringValue: "usersinfo"), scope: chainProvider.usersInfoTableScope)
//        req.lowerBound = account.name
//        req.upperBound = account.name
//
//        do {
//
//            let res = try client.sendSync(req).get()
//
//            print(res)
//            if let userInfo = res.rows.first {
//                account.base64Avatar = userInfo.avatar ?? ""
//                account.fullName = userInfo.name ?? ""
//                account.verified = userInfo.verified ?? false
//            }
//
//            self.finish(retval: account, error: nil)
//
//        } catch {
//            print("ERROR: \(error.localizedDescription)")
//            self.finish(retval: nil, error: error)
//        }
        
    }
    
}
