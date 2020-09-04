//
//  ProtonSigningRequest.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import Foundation
import EOSIO

public struct ProtonSigningRequest: Equatable {
    
    public var requestKey: PublicKey
    public var signer: Account
    public var signingRequest: SigningRequest
    public var resolvedSigningRequest: ResolvedSigningRequest?
    public var requestor: Account?
    public var actions: [ProtonSigningRequestAction]
    
    public var basicTransfer: Bool {
        if let action = self.actions.first, actions.count == 1 {
            return action.basicDisplay.actiontype == ProtonSigningRequestAction.ActionType.transfer ? true : false
        }
        return false
    }
    
}
