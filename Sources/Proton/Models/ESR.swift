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
    
}
