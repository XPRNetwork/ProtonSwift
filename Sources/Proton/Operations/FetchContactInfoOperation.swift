//
//  FetchContactInfoOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import EOSIO
import Foundation

class FetchContactInfoOperation: AbstractOperation {

    var account: Account
    var contactName: String
    var chainProvider: ChainProvider

    init(account: Account, contactName: String, chainProvider: ChainProvider) {
        self.account = account
        self.contactName = contactName
        self.chainProvider = chainProvider
    }

    override func main() {

        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        var req = API.V1.Chain.GetTableRows<UserInfoABI>(code: Name(stringValue: chainProvider.usersInfoTableCode),
                                                         table: Name(stringValue: "usersinfo"),
                                                         scope: chainProvider.usersInfoTableScope)
        req.lowerBound = contactName
        req.upperBound = contactName

        do {

            let res = try client.sendSync(req).get()
            
            var contact = Contact(chainId: chainProvider.chainId, name: contactName)

            if let userInfo = res.rows.first {
                contact.base64Avatar = userInfo.avatar
                contact.nickName = userInfo.name
                contact.verified = userInfo.verified
            }

            finish(retval: contact, error: nil)

        } catch {
            finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.GetTableRows<UserInfoABI>.path)\nERROR => \(error.localizedDescription)"))
        }

    }

}
