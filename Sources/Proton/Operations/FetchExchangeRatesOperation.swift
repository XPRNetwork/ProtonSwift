//
//  FetchExchangeRatesOperation.swift
//  Proton
//
//  Created by Jacob Davis on 3/18/20.
//  Copyright © 2020 Needly, Inc. All rights reserved.
//

import Foundation

class FetchExchangeRatesOperation: AbstractOperation {
    
    var chainProvider: ChainProvider

    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        guard let url = URL(string: chainProvider.exchangeRateUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form proper url exchangeRateUrl endpoint"))
            return
        }

        WebOperations.shared.getRequestJSON(withURL: url) { (result: Result<Any?, Error>) in

            switch result {
            case .success(let rates):
                self.finish(retval: rates as? [[String: Any]], error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching exchange rates\nERROR => \(error.localizedDescription)"))
            }
        }
        
    }
    
}
