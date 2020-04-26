//
//  DeviceOrientationDelegate.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/26/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

protocol OrientationDelegate : class {
    func orientationDidChange (orientation: UIDeviceOrientation, screenSize: CGSize)
}

extension OrientationDelegate {
    
    func addEventListenerForOrientation () {
        
        let nc = NotificationCenter.default
        nc.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] (notification) in
                
            // Define supported orientations
            let supportedOrientations = [UIDeviceOrientation.landscapeLeft, UIDeviceOrientation.landscapeRight, UIDeviceOrientation.portrait]
            
            // Make sure that the current orientation is a supported orientation
            if supportedOrientations.contains(UIDevice.current.orientation) {
                
                // Prepare a screen size to send the reciever
                var screenSize = CGSize.zero
                switch UIDevice.current.orientation {
                case .landscapeRight, .landscapeLeft:
                    screenSize.width = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
                    screenSize.height = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
                case .portrait:
                    screenSize.width = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
                    screenSize.height = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
                default:
                    break
                }
                
                DispatchQueue.main.async {
                    self?.orientationDidChange(orientation: UIDevice.current.orientation, screenSize: screenSize)
                }
                
            }
        }
    }
    
}
