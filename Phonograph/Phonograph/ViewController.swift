//
//  ViewController.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/20/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // For a properly aesthetic demo..
        self.view.backgroundColor = .black
        
        // Define phonograph controller
        let phonographController = PhonographController.shared
        
        // Setup phonograph contoller as a container view controller and install view on parent
        self.addChild(phonographController)
        phonographController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(phonographController.view)
        self.view.addConstraints([
            NSLayoutConstraint(item: phonographController.view!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: phonographController.view!, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: phonographController.view!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300),
            NSLayoutConstraint(item: phonographController.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        ])
        phonographController.didMove(toParent: self)
        
        // Define phonograph record and properties
        let record = PhonographRecord(
            name: "Magnumwumbleopus",
            artist: "Erik Satie",
            sideA: PhonographRecord.Side(
                audioFileURL: URL(fileURLWithPath: Bundle.main.path(forResource: "erik_satie.mp3", ofType: nil)!),
                image: UIImage(named: "record_player_record_side-a")!,
                durations: [945],
                runOutGrooveWidth: 38.50,
                pixelsPerSecondForStylusOnRunOutGroove: 15
            ),
            sideB: PhonographRecord.Side(
                audioFileURL: URL(fileURLWithPath: Bundle.main.path(forResource: "erik_satie.mp3", ofType: nil)!),
                image: UIImage(named: "record_player_record_side-b")!,
                durations: [945],
                runOutGrooveWidth: 38.50,
                pixelsPerSecondForStylusOnRunOutGroove: 15
            ),
            style: .LP,
            orientation: .a,
            leadInGrooveWidth: 46.34,
            pixelsPerSecondForStylusOnLeadInGroove: 25,
            centerLabelDiameter: 581.06,
            centerHoleDiameter: 40
        )
        
        // Insert phonograph record in queue
        phonographController.enqueueRecord(record)
        phonographController.enqueueRecord(record)
        
        // Play (or let don't and let the user initiate play)
        //phonographController.play(animated: true)
    }
}


