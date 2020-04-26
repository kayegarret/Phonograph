//
//  PhonographAVAudioPlayerDelegate.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/25/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit
import AVKit

extension PhonographController : AVAudioPlayerDelegate {
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.stop(animated: true)
        
        if let error = error {
            print("an error occured while decoding audio file data: \(error)")
        }
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        self.stop(animated: false)
    }
    
    
}
