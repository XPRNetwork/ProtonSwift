//
//  FetchProducerOrgOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import WebOperations

class FetchProducerOrgOperation: BaseOperation {
    
    var producer: Producer
    
    init(producer: Producer) {
        self.producer = producer
    }
    
    override func main() {
        
        super.main()
        
        let urlString = producer.url.last == "/" ? String(producer.url.dropLast()) : producer.url
        
        guard let url = URL(string: "\(urlString)/bp.json") else {
            self.finish(retval: nil, error: ProtonError.error("Unable to form proper url bp.json endpoint"))
            return
        }

        WebOperations.shared.request(url: url, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase) { (result: Result<BPJson, Error>) in

            switch result {
            case .success(let bpJson):
                self.producer.org = bpJson.org
                self.finish(retval: self.producer, error: nil)
            case .failure:
                self.finish(retval: nil, error: ProtonError.error("There was an issue fetching bp.json for \(self.producer.url)"))
            }
            
        }
        
    }
    
}
