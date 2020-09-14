//
//  ProtonSigningRequestAction.swift
//  Proton
//
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct ProtonESRAction: Identifiable, Hashable, TokenContractProtocol {
    
    public enum ActionType {
        case transfer, custom
    }
    
    public var id = UUID().uuidString

    public let type: ActionType
    public let account: Name
    public let name: Name
    public let chainId: ChainId
    public let abi: ABI
    public let data: Data

    public static func == (lhs: ProtonESRAction, rhs: ProtonESRAction) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var tokenContract: TokenContract? {
        if type == .transfer, let transferActionABI = transferActionABI {
            return Proton.shared.tokenContracts.first(where: { $0.chainId == String(chainId) && $0.contract == account && $0.symbol == transferActionABI.quantity.symbol })
        }
        return nil
    }
    
    public var transferActionABI: TransferActionABI? {
        return try? ABIDecoder().decode(TransferActionABI.self, from: data)
    }
}
