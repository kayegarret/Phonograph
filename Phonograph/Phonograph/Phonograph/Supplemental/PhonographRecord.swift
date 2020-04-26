//
//  PhonographRecord.swift
//  TestApplication
//
//  Created by Garret Kaye on 2/19/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

class PhonographRecord {
        
    enum Orientation : Int {
        case a = 1
        case b = 2
    }
    
    enum Style : Double {
        case LP = 33.33
        case EP = 45.0
        case single = 78.0
    }
    
    class Side {
        var audioFileURL : URL
        var image : UIImage
        
        /// Duration of each track section (song) in seconds
        var durations : [Double]
        
        /// In pixels
        var runOutGrooveWidth : CGFloat
        
        /// The speed at which the stylus travels accross the run-out groove in pixels / seconds
        var pixelsPerSecondForStylusOnRunOutGroove : Double
        
        /// The time it takes for the stylus to go from the outer edge of the run-out groove to the center label outer edge
        var runOutGrooveDuration : Double {
            return Double(runOutGrooveWidth) / pixelsPerSecondForStylusOnRunOutGroove
        }
        
        init(audioFileURL: URL, image: UIImage, durations: [Double], runOutGrooveWidth: CGFloat, pixelsPerSecondForStylusOnRunOutGroove: Double) {
            
            self.audioFileURL = audioFileURL
            self.image = image
            self.durations = durations
            self.runOutGrooveWidth = runOutGrooveWidth
            self.pixelsPerSecondForStylusOnRunOutGroove = pixelsPerSecondForStylusOnRunOutGroove
        }
    }
    
    var sideUp : Side {
        switch orientation {
        case .a:
            return sideA
        case .b:
            return sideB
        }
    }
    
    var name : String = ""
    var artist : String
    var sideA : Side
    var sideB : Side
    var style : Style
    var orientation : Orientation
    
    /// In pixels
    var leadInGrooveWidth : CGFloat
    
    /// The speed at which the stylus travels accross the lead-in groove in pixels / seconds
    var pixelsPerSecondForStylusOnLeadInGroove : Double
    
    /// The time it takes for the stylus to go from the outer edge of the run-out groove to the center label outer edge
    var leadInGrooveDuration : Double {
        return Double(leadInGrooveWidth) / pixelsPerSecondForStylusOnLeadInGroove
    }
    
    /// In pixels
    var centerLabelDiameter : CGFloat
    
    /// In pixels
    var centerHoleDiameter : CGFloat
    
    
    init(name: String, artist: String, sideA: PhonographRecord.Side, sideB: PhonographRecord.Side, style: Style, orientation: Orientation, leadInGrooveWidth: CGFloat, pixelsPerSecondForStylusOnLeadInGroove: Double, centerLabelDiameter: CGFloat, centerHoleDiameter: CGFloat) {
        
        self.name = name
        self.artist = artist
        self.sideA = sideA
        self.sideB = sideB
        self.style = style
        self.orientation = orientation
        self.leadInGrooveWidth = leadInGrooveWidth
        self.pixelsPerSecondForStylusOnLeadInGroove = pixelsPerSecondForStylusOnLeadInGroove
        self.centerLabelDiameter = centerLabelDiameter
        self.centerHoleDiameter = centerHoleDiameter
    }

}

