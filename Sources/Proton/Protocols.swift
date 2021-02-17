//
//  Protocols.swift
//  Proton
//  
//  Created by Jacob Davis on 4/20/20.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

#if os(macOS)
import AppKit
#endif
import EOSIO
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

protocol AccountProtocol {
    var account: Account? { get }
}

protocol ContactProtocol {
    var contact: Contact? { get }
}

protocol ChainProviderProtocol {
    var chainProvider: ChainProvider? { get }
}

protocol GlobalsXPRProtocol {
    var globalsXPR: GlobalsXPR? { get }
}

protocol Global4Protocol {
    var global4: Global4? { get }
}

protocol GlobalsDProtocol {
    var globalsD: GlobalsD? { get }
}

public protocol AvatarProtocol {
    var defaultBase64Avatar: String { get }
    var base64Avatar: String { get set }
}

protocol TokenBalancesProtocol {
    var tokenBalances: [TokenBalance] { get }
}

protocol TokenBalanceProtocol {
    var tokenBalance: TokenBalance? { get }
}

protocol TokenContractProtocol {
    var tokenContract: TokenContract? { get }
}

protocol TokenContractsProtocol {
    var tokenContracts: [TokenContract] { get }
}

protocol TokenTransferActionsProtocol {
    var tokenTransferActions: [TokenTransferAction] { get }
}

// MARK: - Default protocol implementations

extension AvatarProtocol {
    public var defaultBase64Avatar: String { "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" }
    
    public var avatarImage: Image {
        
        #if os(macOS)
        
        return Image(nsImage: self.avatarNSImage)
        
        #elseif os(iOS)
        
        return Image(uiImage: self.avatarUIImage)
        
        #endif
        
    }
    
    #if os(macOS)
    
    public var avatarNSImage: NSImage {
        
        let defaultAvatar = NSImage(data: Data(base64Encoded: self.defaultBase64Avatar)!)!
        
        if self.base64Avatar.isEmpty {
            return defaultAvatar
        }
        
        if let data = Data(base64Encoded: self.base64Avatar), let image = NSImage(data: data) {
            return image
        }
        
        return defaultAvatar
        
    }
    
    #endif
    
    #if os(iOS)
    
    public var avatarUIImage: UIImage {
        
        let defaultAvatar = UIImage(data: Data(base64Encoded: self.defaultBase64Avatar)!)!
        
        if self.base64Avatar.isEmpty {
            return defaultAvatar
        }
        
        if let data = Data(base64Encoded: self.base64Avatar), let image = UIImage(data: data) {
            return image
        }
        
        return defaultAvatar
        
    }
    
    #endif
}
