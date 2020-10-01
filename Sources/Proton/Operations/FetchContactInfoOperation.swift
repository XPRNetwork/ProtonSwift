//
//  FetchContactInfoOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchContactInfoOperation: BaseOperation {

    var contactName: String
    var chainProvider: ChainProvider

    init(contactName: String, chainProvider: ChainProvider) {
        self.contactName = contactName
        self.chainProvider = chainProvider
    }

    override func main() {
        
        super.main()

        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        var req = API.V1.Chain.GetTableRows<UserInfoABI>(code: Name(stringValue: "eosio.proton"),
                                                         table: Name(stringValue: "usersinfo"),
                                                         scope: "eosio.proton")
        req.lowerBound = contactName
        req.upperBound = contactName

        do {

            let res = try client.sendSync(req).get()
            
            var contact = Contact(chainId: chainProvider.chainId, name: contactName)

            if let userInfo = res.rows.first {
                contact.base64Avatar = userInfo.avatar
                contact.userDefinedName = userInfo.name
                contact.verified = userInfo.verified
            }

            finish(retval: contact, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}
