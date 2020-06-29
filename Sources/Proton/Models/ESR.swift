//
//  ESR.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//

import Foundation
import EOSIO

public struct ESR: Equatable {
    
    public var requestor: Account
    public var signer: Account
    public var signingRequest: SigningRequest
    public var sid: String
    public var resolved: ResolvedSigningRequest?
    public var actions: [ESRAction]
    
    public var basicTransfer: Bool {
        if let action = self.actions.first, actions.count == 1 {
            return action.basicDisplay.actiontype == ESRAction.ActionType.transfer ? true : false
        }
        return false
    }
    
    public static var testObject: ESR {
        
        return ESR(requestor: Account(chainId: "71ee83bcf52142d61019d95f9cc5427ba6a0d7ff8accd9e2088ae2abeaf3d3dd", name: "requestor"),
                    signer: Account(chainId: "71ee83bcf52142d61019d95f9cc5427ba6a0d7ff8accd9e2088ae2abeaf3d3dd", name: "signer"),
                    signingRequest: try! SigningRequest("esr://gmMsfNe856ui0zUByZvxc446VS9bcP1_15mbjzi6Hq1-9fnyXWZGRgYEWPHWyIjJJqOkpKDYSl-_tFg3OTWvpCgxx1C3PDEnJ7VENyczL1s3JTU3Xy85J780Ja00L7kkMz-vWC8vtUQ_sbQkg5k9MTk5vzSvhK0ksTg7p5K5ODNFJS3ZJNki0dRE1yjVyFDXxMTIWDfROMVENyXJxMI00dAwOcU4lamo2I5ci4tSQVYDAA"),
                    sid: "123", resolved: nil, actions: [ESRAction(account: Name("eosio.token"), name: Name("transfer"),
                    chainId: "71ee83bcf52142d61019d95f9cc5427ba6a0d7ff8accd9e2088ae2abeaf3d3dd",
                    basicDisplay: ESRAction.BasicDisplay(actiontype: .transfer, name: "Proton", secondary: "1 XPT",
                                                         extra: "", tokenContract: TokenContract.testObject), abi: TransferActionABI.abi)])
        
    }
}
