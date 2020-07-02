//
//  FetchExchangeRatesOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright © 2020 Metallicus, Inc. All rights reserved.
//

import Foundation

class FetchExchangeRatesOperation: AbstractOperation {
    
    var chainProvider: ChainProvider

    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        guard let baseUrl = Proton.config?.baseUrl else {
            fatalError("⚛️ PROTON ERROR: BaseUrl must be valid")
        }
        
        guard let url = URL(string: baseUrl+chainProvider.exchangeRateUrl) else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Unable to form proper url exchangeRateUrl endpoint"))
            return
        }

        WebOperations.shared.request(url: url) { (result: Result<Any?, Error>) in

            switch result {
            case .success(let rates):
                self.finish(retval: rates as? [[String: Any]], error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching exchange rates\nERROR => \(error.localizedDescription)"))
            }
        }
        
    }
    
}
