//
//  PhonographTonearmView.swift
//  TestApplication
//
//  Created by Garret Kaye on 2/25/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

class PhonographTonearmView : UIImageView {
    
    public var anchorPoint : CGPoint { get { return layer.anchorPoint } set { layer.anchorPoint = newValue }}
    public var stylusPoint = CGPoint(x: 0, y: 1.0)
    public var trueZeroFrame = CGRect.zero
    
    
    override init(image: UIImage?) {
        super.init(image: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
