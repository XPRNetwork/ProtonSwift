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
        
        guard let url = URL(string: baseUrl+chainProvider.exchangeRatePath+"/info") else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form proper url exchangeRateUrl endpoint"))
            return
        }

        WebOperations.shared.request(url: url, errorModel: NilErrorModel.self) { (result: Result<[ExchangeRate], WebError>) in
            switch result {
            case .success(let exchangeRates):
                self.finish(retval: exchangeRates, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: Proton.ProtonError(message: "There was an issue fetching exchange rates \(error.localizedDescription)"))
            }
        }
        
    }
    
}
