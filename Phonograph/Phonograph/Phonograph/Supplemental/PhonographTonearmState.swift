//
//  PhonographTonearmState.swift
//  TestApplication
//
//  Created by Garret Kaye on 3/4/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import Foundation

extension PhonographController {
    
    enum TonearmState : Int {
        case tonearmIsOnRest
        case tonearmNotOnRecord
        case userIsHoldingTonearm
        case tonearmIsOnLeadInGroove
        case tonearmIsOnVinylTrack
        case tonearmIsOnRunOutGroove
        case tonearmIsOnCenterLabel
        
        var causesRecordToSpin : Bool {
            
            switch self {
            case .tonearmIsOnRest:
                return false
            case .tonearmNotOnRecord:
                return true
            case .userIsHoldingTonearm:
                return true
            case .tonearmIsOnLeadInGroove:
                return true
            case .tonearmIsOnVinylTrack:
                return true
            case .tonearmIsOnRunOutGroove:
                return true
            case .tonearmIsOnCenterLabel:
                return false
            }
        }
        
        var causesTrackToPlay : Bool {
            
            switch self {
            case .tonearmIsOnRest:
                return false
            case .tonearmNotOnRecord:
                return false
            case .userIsHoldingTonearm:
                return false
            case .tonearmIsOnLeadInGroove:
                return false
            case .tonearmIsOnVinylTrack:
                return true
            case .tonearmIsOnRunOutGroove:
                return false
            case .tonearmIsOnCenterLabel:
                return false
            }
        }
        
    }
}
