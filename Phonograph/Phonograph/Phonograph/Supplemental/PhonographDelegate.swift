//
//  PhonographDelegate.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/25/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

protocol PhonographDelegate : class {
    
    /// Occurs whenever tonearm is on the actively spinning vinyl track sound grooves but not playing audio. Also called upon release.
    func phonographIsAssumedBuffering (_ phonographController: PhonographController, isAssumedBuffering: Bool)
    
    func phonographTonearmStateWillChange (_ phonographController: PhonographController, newTonearmState: PhonographController.TonearmState)
}
