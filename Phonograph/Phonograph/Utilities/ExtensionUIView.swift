//
//  ExtensionUIView.swift
//  Phonograph
//
//  Created by Garret Kaye on 4/20/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

extension UIView {
    
    func showPoint (_ scalePoint: CGPoint, forBounds: CGRect? = nil) {
                
        let dot = UIView()
        dot.backgroundColor = .red
        dot.frame.size = CGSize(width: 2, height: 2)
        dot.center = CGPoint(
            x: scalePoint.x * (forBounds?.width ?? self.bounds.width),
            y: scalePoint.y * (forBounds?.height ?? self.bounds.height)
        )
        self.addSubview(dot)
    }
    
    func getAllConstraints() -> (top: NSLayoutConstraint?, right: NSLayoutConstraint?, bottom: NSLayoutConstraint?, left: NSLayoutConstraint?, centerX: NSLayoutConstraint?, centerY: NSLayoutConstraint?, width: NSLayoutConstraint?, height: NSLayoutConstraint?) {
        
        var allConstraints : (top: NSLayoutConstraint?, right: NSLayoutConstraint?, bottom: NSLayoutConstraint?, left: NSLayoutConstraint?, centerX: NSLayoutConstraint?, centerY: NSLayoutConstraint?, width: NSLayoutConstraint?, height: NSLayoutConstraint?) = (top: nil, right: nil, bottom: nil, left: nil, centerX: nil, centerY: nil, width: nil, height: nil)
        
        guard let view = self.superview else { return allConstraints }
        
        for constraint in view.constraints {
            if let subview = constraint.firstItem as? UIView {
                if subview == self {
                    switch constraint.firstAttribute {
                    case .top, .topMargin:
                        allConstraints.top = constraint
                    case .right, .rightMargin:
                        allConstraints.right = constraint
                    case .bottom, .bottomMargin:
                        allConstraints.bottom = constraint
                    case .left, .leftMargin:
                        allConstraints.left = constraint
                    case .centerX:
                        allConstraints.centerX = constraint
                    case .centerY:
                        allConstraints.centerY = constraint
                    case .width:
                        allConstraints.width = constraint
                    case .height:
                        allConstraints.height = constraint
                    default:
                        continue
                    }
                }
            }
        }

        return allConstraints
        
    }
    
    func getConstraint(whereFirstAttributeIsEqualTo firstAttribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        
        guard let view = self.superview else { return nil }
        
        guard let index = view.constraints.firstIndex(where: { (constraint) -> Bool in
            if constraint.firstAttribute == firstAttribute {
                if let theView = constraint.firstItem as? UIView {
                    if theView == self {
                        return true
                    } else {
                        return false
                    }
                } else {
                    return false
                }
            } else {
                return false
            }
        })
            else {
                return nil
        }
        
        return view.constraints[index]
        
    }
}
