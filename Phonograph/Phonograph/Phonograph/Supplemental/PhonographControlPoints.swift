//
//  PhonographControlPoints.swift
//  TestApplication
//
//  Created by Garret Kaye on 2/22/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

extension PhonographController {
    
    struct ControlPoints {
        
        var tonearmAnchorPoint : CGPoint
        var tonearmStylusPoint : CGPoint
        var tonearmLastTouchdownAngle : CGFloat?
        
        /// The angle (in rads) of when the tonearm is 270 degrees (3/2π rads) on a standard cartesian plane
        var tonearmTrueZeroAngle : CGFloat
        
        /// The angle (in rads) of the tonearm when the stylus is over the direct center of the record
        var tonearmTrueCenterAngle : CGFloat
        
        /// The angle (in rads) of the tonearm when it is on the outer edge of the lead-in groove
        var leadInGrooveStartAngle : CGFloat
        
        /// The angle (in rads) of the tonearm when it is on the inner edge of the lead-in groove
        var leadInGrooveEndAngle : CGFloat
        
        /// The angle (in rads) of the tonearm when it is on the outer edge of the vinyl track
        var vinylTrackStartAngle : CGFloat
        
        /// The angle (in rads) of the tonearm when it is on the inner edge of the vinyl track
        var vinylTrackEndAngle : CGFloat
        
        /// The angle (in rads) of the tonearm when it is on the outer edge of the run-out groove
        var runOutGrooveStartAngle : CGFloat
        
        /// The angle (in rads) of the tonearm when it is on the inner edge of the run-out groove
        var runOutGrooveEndAngle : CGFloat
        
        init (tonearmFrame: CGRect, tonearmAnchorPoint: CGPoint, tonearmStylusPoint: CGPoint, boardBounds: CGRect, leadInGrooveWidth: CGFloat, centerLabelDiameter: CGFloat, runOutGrooveWidth: CGFloat, recordDiameter: CGFloat, appliedRecordImageScale: CGFloat) {
            
            // Passed tone arm anchor point and stylus point are in scale format. Resolve actual points in pixels
            let tonearmAnchorPointActual = CGPoint(x: tonearmAnchorPoint.x * tonearmFrame.size.width, y: tonearmAnchorPoint.y * tonearmFrame.size.height)
            let tonearmStylusPointActual = CGPoint(x: tonearmStylusPoint.x * tonearmFrame.size.width, y: tonearmStylusPoint.y * tonearmFrame.size.height)
            
            // Tone arm anchor point actual and stylus point actual are relative to the tone arm bounds. Translate to board bounds
            self.tonearmAnchorPoint = CGPoint(x: tonearmFrame.minX + tonearmAnchorPointActual.x, y: tonearmFrame.minY + tonearmAnchorPointActual.y)
            self.tonearmStylusPoint = CGPoint(x: tonearmFrame.minX + tonearmStylusPointActual.x, y: tonearmFrame.minY + tonearmStylusPointActual.y)
            
            // Calculate tonearm dimensions
            let tonearmXLength = sqrt(pow(tonearmStylusPointActual.x - tonearmAnchorPointActual.x, 2))
            let tonearmYLength = sqrt(pow(tonearmStylusPointActual.y - tonearmAnchorPointActual.y, 2))
            let tonearmLength = sqrt(pow(tonearmStylusPointActual.x - tonearmAnchorPointActual.x, 2) + pow(tonearmStylusPointActual.y - tonearmAnchorPointActual.y, 2))
            
            // Set true zero and center angles
            self.tonearmTrueZeroAngle = -atan(tonearmXLength / tonearmYLength)
            self.tonearmTrueCenterAngle = self.tonearmTrueZeroAngle + CGFloat.pi/4
            
            // Define distance between all the circle constructs and relevant radii
            let distanceBetweenCircles = tonearmLength/sqrt(2)
            let recordRadius = (recordDiameter * appliedRecordImageScale) / 2
            let vinylTrackRadius = ((recordDiameter - leadInGrooveWidth * 2) * appliedRecordImageScale) / 2
            let runOutGrooveRadius = ((centerLabelDiameter + runOutGrooveWidth * 2) * appliedRecordImageScale) / 2
            let centerLabelRadius = (centerLabelDiameter * appliedRecordImageScale) / 2
            
            // Method to calculate the angle of intersection between circle B's center point and the right most intersection point of circle A and circle B
            func angleFromCircleEquation (circleARadius: CGFloat, circleBRadius: CGFloat, distanceBetweenCircles: CGFloat) -> CGFloat {
                
                // Solve for the right most point where the circles intersect
                let derivedExpression : CGFloat = ((pow(circleBRadius, 2) - pow(circleARadius, 2)) / (-2 * distanceBetweenCircles)) + distanceBetweenCircles
                let intersectionPointY = min(
                    (derivedExpression + sqrt(-pow(derivedExpression, 2) + 2 * pow(circleARadius, 2))) / 2,
                    (derivedExpression - sqrt(-pow(derivedExpression, 2) + 2 * pow(circleARadius, 2))) / 2
                )
                let intersectionPointX = derivedExpression - intersectionPointY
                let intersectionPoint = CGPoint(x: intersectionPointX, y: intersectionPointY)
                
                // Calculate and return angle
                let triangleConstructLegX = sqrt(pow(intersectionPoint.x - distanceBetweenCircles, 2))
                let triangleConstructLegY = sqrt(pow(intersectionPoint.y - distanceBetweenCircles, 2))
                return atan(triangleConstructLegX / triangleConstructLegY)
            }
            
            // Set angles
            self.leadInGrooveStartAngle = angleFromCircleEquation(circleARadius: recordRadius, circleBRadius: tonearmLength, distanceBetweenCircles: distanceBetweenCircles) + self.tonearmTrueZeroAngle
            self.leadInGrooveEndAngle = angleFromCircleEquation(circleARadius: vinylTrackRadius, circleBRadius: tonearmLength, distanceBetweenCircles: distanceBetweenCircles) + self.tonearmTrueZeroAngle
            self.vinylTrackStartAngle = leadInGrooveEndAngle
            self.vinylTrackEndAngle = angleFromCircleEquation(circleARadius: runOutGrooveRadius, circleBRadius: tonearmLength, distanceBetweenCircles: distanceBetweenCircles) + self.tonearmTrueZeroAngle
            self.runOutGrooveStartAngle = vinylTrackEndAngle
            self.runOutGrooveEndAngle = angleFromCircleEquation(circleARadius: centerLabelRadius, circleBRadius: tonearmLength, distanceBetweenCircles: distanceBetweenCircles) + self.tonearmTrueZeroAngle
            
        }
    }
}
