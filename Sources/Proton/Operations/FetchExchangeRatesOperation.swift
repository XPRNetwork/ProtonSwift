//
//  FetchExchangeRatesOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import WebOperations

class FetchExchangeRatesOperation: BaseOperation {
    
    var chainProvider: ChainProvider

    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }
    
    override func main() {
        
        super.main()
        
        guard let baseUrl = Proton.config?.baseUrl else {
            fatalError("⚛️ PROTON ERROR: BaseUrl must be valid")
        }
        
        guard let url = URL(string: baseUrl+chainProvider.exchangeRatePath) else {
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
