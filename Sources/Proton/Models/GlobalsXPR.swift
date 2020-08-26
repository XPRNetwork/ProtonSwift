//
//  File.swift
//  
//
//  Created by Jacob Davis on 8/26/20.
//
import Foundation

public struct GlobalsXPR: Codable {

    public let requiredBPVotes: Int
    public let unstakePeriod: TimeInterval
    public let claimInterval: TimeInterval
    public let processInterval: TimeInterval
    
    init(globalsXPRABI: GlobalsXPRABI) {
        self.requiredBPVotes = Int(globalsXPRABI.min_bp_reward)
        self.unstakePeriod = TimeInterval(globalsXPRABI.unstake_period)
        self.claimInterval = TimeInterval(globalsXPRABI.voters_claim_interval)
        self.processInterval = TimeInterval(globalsXPRABI.process_interval)
    }

}
