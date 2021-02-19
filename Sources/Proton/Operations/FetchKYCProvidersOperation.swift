//
//  FetchKYCProvidersOperation.swift
//  
//
//  Created by Jacob Davis on 2/19/21.
//

import EOSIO
import Foundation
import WebOperations

class FetchKYCProvidersOperation: BaseOperation {

    var chainProvider: ChainProvider

    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }

    override func main() {

        super.main()
        
        guard let url = URL(string: chainProvider.chainUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form chainProvider URL"))
            return
        }

        let client = Client(address: url)
        let req = API.V1.Chain.GetTableRows<KYCProviderABI>(code: Name(stringValue: "eosio.proton"),
                                                           table: Name(stringValue: "kycproviders"),
                                                           scope: Name(stringValue: "eosio.proton"))

        do {

            let res = try client.sendSync(req).get()
            let retval = res.rows.filter({ $0.blisted != true }).map({ KYCProvider(kycProviderABI: $0) })
            
            finish(retval: retval, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }

    }

}
