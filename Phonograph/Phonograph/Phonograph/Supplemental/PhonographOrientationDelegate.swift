//
//  PhonographOrientationDelegate.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/26/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

extension PhonographController : OrientationDelegate {
    
    func orientationDidChange(orientation: UIDeviceOrientation, screenSize: CGSize) {
        
        // Check if phonograph was playing when this happened
        if self.tonearmState == .tonearmIsOnVinylTrack {
            
            // Recalibrate stylus position
            self.play(animated: false)
        }
    }
}
