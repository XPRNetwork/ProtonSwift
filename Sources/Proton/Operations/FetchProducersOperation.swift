//
//  FetchProducersOperation.swift
//  Proton
//
//  Created by Jacob Davis on 7/24/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation
import WebOperations

class FetchProducersOperation: BaseOperation {

    var chainProvider: ChainProvider

    init(chainProvider: ChainProvider) {
        self.chainProvider = chainProvider
    }

    override func main() {

        super.main()
        
        
        guard let url = URL(string: "\(chainProvider.chainUrl)/v1/chain/get_table_rows") else {
            self.finish(retval: nil, error: ProtonError.error("MESSAGE => Missing chainProvider url"))
            return
        }
        
        let params = [
            "scope": "eosio",
            "table": "producers",
            "code": "eosio",
            "json": true,
            "limit": 100
            ] as [String : Any]

        WebOperations.shared.request(method: .post, url: url, parameters: params) { (result: Result<[String: Any]?, Error>) in

            switch result {
            case .success(let res):
                guard let res = res else { self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching producers table")); return }
                guard let rows = res["rows"] as? [[String: Any]], rows.count > 0 else { self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching producers table")); return }

                let decoder = JSONDecoder()
                var producers: [ProducerABI]?

                if let data = try? JSONSerialization.data(withJSONObject: rows, options: .prettyPrinted) {
                    producers = try? decoder.decode([ProducerABI].self, from: data)
                }
                
                producers?.removeAll(where: { $0.is_active != 0x01 }) // remove non-active producers
                producers?.sort {                                     // sort from top to bottom
                    $0.total_votes.value > $1.total_votes.value
                }

                self.finish(retval: producers, error: nil)
            case .failure(let error):
                self.finish(retval: nil, error: ProtonError.error("MESSAGE => There was an issue fetching producers table\nERROR => \(error.localizedDescription)"))
            }

        }

//        let client = Client(address: url)
//        var req = API.V1.Chain.GetTableRows<ProducerABI>(code: Name(stringValue: "eosio"),
//                                                         table: Name(stringValue: "producers"),
//                                                         scope: "eosio")
//        //req.limit = 100
//
//        do {
//
//            let res = try client.sendSync(req).get()
//            finish(retval: res.rows, error: nil)
//
//        } catch {
//            finish(retval: nil, error: ProtonError.chain("RPC => \(API.V1.Chain.GetTableRows<ProducerABI>.path)\nERROR => \(error.localizedDescription)"))
//        }

    }

}
