//
//  PhonographView.swift
//  TestApplication
//
//  Created by Garret Kaye on 2/15/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

class PhonographView : UIView {
    
    var board = UIImageView(image: UIImage(named: "record_player_board"))
    var turntable = UIImageView(image: UIImage(named: "record_player_turntable"))
    var tonearmRest = UIImageView(image: UIImage(named: "record_player_tonearm_rest"))
    var turntableCenterPeg = UIImageView(image: UIImage(named: "record_player_turntable_center_peg"))
    var record = UIImageView()
    var tonearm = PhonographTonearmView(image: UIImage(named: "record_player_tonearm"))
    var flipperScrollView = UIScrollView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup () {
        
        self.board.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.board)
        self.addConstraints([
            NSLayoutConstraint(item: self.board, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.board, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.board, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.board, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        
        
        self.turntable.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.turntable)
        
        
        self.tonearmRest.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.tonearmRest)
        
        
        self.turntableCenterPeg.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.turntableCenterPeg)
        self.addConstraints([
            NSLayoutConstraint(item: self.turntableCenterPeg, attribute: .centerX, relatedBy: .equal, toItem: self.turntable, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.turntableCenterPeg, attribute: .centerY, relatedBy: .equal, toItem: self.turntable, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.turntableCenterPeg, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.turntableCenterPeg, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        ])
        
        
        self.record.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.record)
        self.addConstraints([
            NSLayoutConstraint(item: self.record, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: -15),
            NSLayoutConstraint(item: self.record, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 15),
            NSLayoutConstraint(item: self.record, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.75, constant: 0),
            NSLayoutConstraint(item: self.record, attribute: .height, relatedBy: .equal, toItem: self.record, attribute: .width, multiplier: 1.0, constant: 0)
        ])
        
        self.addConstraints([
            NSLayoutConstraint(item: self.turntable, attribute: .centerX, relatedBy: .equal, toItem: self.record, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.turntable, attribute: .centerY, relatedBy: .equal, toItem: self.record, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.turntable, attribute: .width, relatedBy: .equal, toItem: self.record, attribute: .width, multiplier: 0.9, constant: 0),
            NSLayoutConstraint(item: self.turntable, attribute: .height, relatedBy: .equal, toItem: self.record, attribute: .height, multiplier: 0.9, constant: 0)
        ])
        
        
        self.flipperScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.flipperScrollView.backgroundColor = .clear
        self.flipperScrollView.isPagingEnabled = true
        self.flipperScrollView.bounces = false
        self.flipperScrollView.isUserInteractionEnabled = true
        self.flipperScrollView.showsVerticalScrollIndicator = false
        self.flipperScrollView.showsHorizontalScrollIndicator = false
        self.addSubview(self.flipperScrollView)
        self.addConstraints([
            NSLayoutConstraint(item: self.flipperScrollView, attribute: .centerX, relatedBy: .equal, toItem: self.record, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.flipperScrollView, attribute: .centerY, relatedBy: .equal, toItem: self.record, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.flipperScrollView, attribute: .width, relatedBy: .equal, toItem: self.record, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.flipperScrollView, attribute: .height, relatedBy: .equal, toItem: self.record, attribute: .height, multiplier: 1.0, constant: 0)
        ])
        
        
        self.tonearm.translatesAutoresizingMaskIntoConstraints = false
        self.tonearm.isUserInteractionEnabled = true
        self.addSubview(self.tonearm)
        self.addConstraints([
            NSLayoutConstraint(item: self.tonearm, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 15),
            NSLayoutConstraint(item: self.tonearm, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -15),
            NSLayoutConstraint(item: self.tonearm, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.tonearm, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        ])
        
        
        // Adjust tonearm rest position as needed to suit the tone arm
        self.addConstraints([
            NSLayoutConstraint(item: self.tonearmRest, attribute: .right, relatedBy: .equal, toItem: self.tonearm, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.tonearmRest, attribute: .centerY, relatedBy: .equal, toItem: self.tonearm, attribute: .centerY, multiplier: 1.33, constant: 0),
            NSLayoutConstraint(item: self.tonearmRest, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 25),
            NSLayoutConstraint(item: self.tonearmRest, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 25)
        ])
    }
}

