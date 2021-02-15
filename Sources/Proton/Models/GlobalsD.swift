//
//  GlobalsD.swift
//  Proton
//
//  Created by Jacob Davis on 2/15/21.
//  Copyright (c) 2020 Proton Chain LLC, Delaware
//

import EOSIO
import Foundation

public struct GlobalsD: Codable {
    
    public let totalStaked: Int64
    public let totalRStaked: Int64
    public let totalRVoters: Int64
    public let notClaimed: Int64
    public let pool: Int64
    public let processTime: Int64
    public let processTimeUpD: Int64
    public let isProcessing: Bool
    public let processFrom: Name
    public let processQuant: UInt64
    public let processRStaked: UInt64
    public let processed: UInt64
    public let spare1: Int64
    public let spare2: Int64
    
    init(globalsDABI: GlobalsDABI) {
        self.totalStaked = globalsDABI.totalstaked
        self.totalRStaked = globalsDABI.totalrstaked
        self.totalRVoters = globalsDABI.totalrvoters
        self.notClaimed = globalsDABI.notclaimed
        self.pool = globalsDABI.pool
        self.processTime = globalsDABI.processtime
        self.processTimeUpD = globalsDABI.processtimeupd
        self.isProcessing = globalsDABI.isprocessing
        self.processFrom = globalsDABI.processFrom
        self.processQuant = globalsDABI.processQuant
        self.processRStaked = globalsDABI.processrstaked
        self.processed = globalsDABI.processed
        self.spare1 = globalsDABI.spare1
        self.spare2 = globalsDABI.spare2
    }
    
}
