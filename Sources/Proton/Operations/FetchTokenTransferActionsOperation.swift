//
//  FetchTokenTransferActionsOperation.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import EOSIO
import WebOperations

class FetchTokenTransferActionsOperation: BaseOperation {
    
    var account: Account
    var chainProvider: ChainProvider
    var tokenContract: TokenContract
    var tokenBalance: TokenBalance
    let limt = 50
    
    init(account: Account, tokenContract: TokenContract, chainProvider: ChainProvider,
         tokenBalance: TokenBalance) {
        
        self.account = account
        self.tokenContract = tokenContract
        self.chainProvider = chainProvider
        self.tokenBalance = tokenBalance
    }
    
    override func main() {
        
        super.main()
        
        guard let url = URL(string: chainProvider.hyperionHistoryUrl) else {
            self.finish(retval: nil, error: Proton.ProtonError(message: "Missing chainProvider url"))
            return
        }

        let client = Client(address: url)
        
        struct TransferActionData: ABIDecodable {
            let from: Name
            let to: Name
            let amount: Double
            let symbol: String
            let memo: String
            let quantity: Asset
        }

        var req = API.V2.Hyperion.GetActions<TransferActionData>(self.account.name)
        req.filter = "\(self.tokenContract.contract.stringValue):transfer"
        req.transferSymbol = self.tokenContract.symbol.name
        req.limit = UInt(self.limt)
        req.sort = .desc

        do {

            let res = try client.sendSync(req).get()

            var tokenTranfsers = Set<TokenTransferAction>()

            for action in res.actions {
            
                let transferAction = TokenTransferAction(globalSequence: action.globalSequence ?? 0, chainId: account.chainId, accountId: account.id,
                                                         tokenBalanceId: tokenBalance.id, tokenContractId: tokenContract.id,
                                                         name: "transfer", contract: tokenContract.contract,
                                                         trxId: String(action.trxId), date: action.timestamp.date,
                                                         sent: self.account.name.stringValue == action.act.data.from.stringValue ? true : false,
                                                         from: action.act.data.from,
                                                         to: action.act.data.to, quantity: action.act.data.quantity, memo: action.act.data.memo)
                
                tokenTranfsers.update(with: transferAction)

            }

            finish(retval: tokenTranfsers, error: nil)

        } catch {
            finish(retval: nil, error: Proton.ProtonError(message: error.localizedDescription))
        }
        
    }
    
}
