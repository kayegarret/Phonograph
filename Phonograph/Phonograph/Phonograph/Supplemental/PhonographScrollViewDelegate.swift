//
//  PhonographScrollViewDelegate.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/25/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

fileprivate var recordSideBeforeUserInteraction : PhonographRecord.Orientation?

extension PhonographController : UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        recordSideBeforeUserInteraction = self.currentRecord?.orientation
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard scrollView == self.container.flipperScrollView
            else { return }
        
        self.container.record.layer.zPosition = CGFloat(MAXFLOAT)
        
        let currentContentOffset = scrollView.contentOffset
        let pageSize = scrollView.frame.size
        let offsetFromCenter = CGPoint(x: pageSize.width - currentContentOffset.x, y: pageSize.height - currentContentOffset.y)
        
        
        let flipAnglePeak = CGFloat.pi/2
        let flipAngleBase = -flipAnglePeak
        let scalePeak = CGFloat(1.25)
        let scaleBase = CGFloat(1)
        let scaleToAngleRatio = (scalePeak - scaleBase) / flipAnglePeak
                
        var calculatedFlipAngle = CGPoint(
            x: (offsetFromCenter.x / (pageSize.width / 2)) * flipAnglePeak,
            y: (offsetFromCenter.y / (pageSize.height / 2)) * flipAnglePeak
        )
        
        self.changeRecordSideIfNeeded(flipAnglePeak: flipAnglePeak, calculatedAngleRaw: calculatedFlipAngle)
        
        if calculatedFlipAngle.x > flipAnglePeak {
            calculatedFlipAngle.x = flipAnglePeak - (calculatedFlipAngle.x - flipAnglePeak)
        }
        if calculatedFlipAngle.x < flipAngleBase {
            calculatedFlipAngle.x = flipAngleBase + (flipAngleBase - calculatedFlipAngle.x)
        }
        
        if calculatedFlipAngle.y > flipAnglePeak {
            calculatedFlipAngle.y = flipAnglePeak - (calculatedFlipAngle.y - flipAnglePeak)
        }
        if calculatedFlipAngle.y < flipAngleBase {
            calculatedFlipAngle.y = flipAngleBase + (flipAngleBase - calculatedFlipAngle.y)
        }
                
        let scale = 1 + max(abs(calculatedFlipAngle.x), abs(calculatedFlipAngle.y)) * scaleToAngleRatio
        
        let currentRecordAngle = atan2(self.container.record.layer.transform.m12, self.container.record.layer.transform.m11)
        
        let transformToApply = CATransform3DConcat(
            CATransform3DMakeRotation(currentRecordAngle, 0, 0, 1), // Current rotation around the Z axis on turntable
            CATransform3DConcat(
                CATransform3DMakeScale(scale, scale, 1), // New scale
                CATransform3DConcat(
                    CATransform3DMakeRotation(calculatedFlipAngle.y, 1, 0, 0), // New rotation around X axis
                    CATransform3DMakeRotation(calculatedFlipAngle.x, 0, 1, 0) // New rotation around Y axis
                )
            )
        )
        
        self.container.record.layer.transform = transformToApply
    }

    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        guard scrollView == self.container.flipperScrollView
            else { return }
        
        self.container.record.layer.zPosition = CGFloat.zero
        
        
        // Ensure that the flipper scroll view content size is proportional to record size for pagation
        self.container.flipperScrollView.delegate = nil
        self.container.flipperScrollView.contentOffset.y = self.container.record.frame.size.height
        self.container.flipperScrollView.contentOffset.x = self.container.record.frame.size.width
        self.container.flipperScrollView.delegate = self
        
        // Remove orientation storage from memory
        recordSideBeforeUserInteraction = nil
    }
    
    fileprivate func changeRecordSideIfNeeded (flipAnglePeak: CGFloat, calculatedAngleRaw: CGPoint) {
        
        guard let startingSide = recordSideBeforeUserInteraction,
            let currentRecord = self.currentRecord
            else { return }
        
        let numberOfFlips = CGPoint(x: Int(abs(calculatedAngleRaw.x / flipAnglePeak)), y: Int(abs(calculatedAngleRaw.y / flipAnglePeak)))
        let totalNumberOfFlips = Int(numberOfFlips.x + numberOfFlips.y)

        guard numberOfFlips.x < 2 && numberOfFlips.y < 2
            else { return }
        
        if (totalNumberOfFlips % 2 != 0) {
            if currentRecord.orientation == startingSide {
                self.flip(animated: false)
            }
        }
        else {
            if currentRecord.orientation != startingSide {
                self.flip(animated: false)
            }
        }
    }
}
