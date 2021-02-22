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
        
        if !self.producer.isActive {
            self.finish(retval: self.producer, error: nil)
            return
        }
        
        let urlString = producer.url.last == "/" ? String(producer.url.dropLast()) : producer.url
        
        guard let url = URL(string: "\(urlString)/bp.json") else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Unable to form proper url bp.json endpoint"))
            return
        }

        WebOperations.shared.request(url: url, timeoutInterval: 2, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase, errorModel: NilErrorModel.self) { (result: Result<BPJson, WebError>) in
            switch result {
            case .success(let bpJson):
                self.producer.org = bpJson.org
                self.finish(retval: self.producer, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: Proton.ProtonError(message: "There was an issue fetching bp.json for \(self.producer.url): \(error)"))
            }
            
        }
        
    }
    
}
