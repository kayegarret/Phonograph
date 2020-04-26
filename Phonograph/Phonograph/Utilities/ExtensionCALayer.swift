//
//  ExtensionCALayer.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/25/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

extension CALayer {
    
    func applyStickyTransformationAnimation (moveToNewValue newValue: CATransform3D, withDuration duration: Double, andTimingFunction timingFunction: CAMediaTimingFunctionName, completion: (() -> Void)? = nil) {
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: timingFunction))
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock {
            
            // Call completion
            completion?()
        }
        
        let transformAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
        transformAnimation.fromValue = self.transform
        self.transform = newValue
        self.add(transformAnimation, forKey: #keyPath(CALayer.transform))
        
        CATransaction.commit()
    }
    
    func applyStickyTransformationAnimation (moveToNewValue newValue: CATransform3D, withDuration duration: Double, opacityChange: Float, andTimingFunction timingFunction: CAMediaTimingFunctionName, completion: (() -> Void)? = nil) {
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: timingFunction))
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock {
            
            // Call completion
            completion?()
        }
        
        let transformAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
        transformAnimation.fromValue = self.transform
        self.transform = newValue
        self.add(transformAnimation, forKey: #keyPath(CALayer.transform))
        
        let opacityAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        opacityAnimation.fromValue = self.opacity
        self.opacity = opacityChange
        self.add(opacityAnimation, forKey: #keyPath(CALayer.opacity))
        
        CATransaction.commit()
    }
    
}

