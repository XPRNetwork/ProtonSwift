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
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: WebServiceError.error("ERROR: Missing url for get table rows"))
            return
        }

        let client = Client(address: url)
        var req = API.V1.Chain.GetTableRows<UserInfoABI>(code: Name(stringValue: chainProvider.usersInfoTableCode),
                                                      table: Name(stringValue: "usersinfo"),
                                                      scope: chainProvider.usersInfoTableScope)
        req.lowerBound = account.name
        req.upperBound = account.name

        do {

            let res = try client.sendSync(req).get()

            if let userInfo = res.rows.first {
                account.base64Avatar = userInfo.avatar
                account.fullName = userInfo.name
                account.verified = userInfo.verified
            }

            self.finish(retval: account, error: nil)

        } catch {
            print("ERROR: \(error.localizedDescription)")
            self.finish(retval: nil, error: error)
        }
        
    }
    
}
