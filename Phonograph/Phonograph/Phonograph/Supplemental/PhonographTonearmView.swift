//
//  PhonographTonearmView.swift
//  TestApplication
//
//  Created by Garret Kaye on 2/25/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

class PhonographTonearmView : UIImageView {
    
    /// PhonographTonearmView point of rotation. Should be, but not necessarily, always the same as the anchor point of the layer
    public var anchorPoint = CGPoint(x: 0.76, y: 0.2125)
    
    /// PhonographTonearmView point where the needle is located
    public var stylusPoint = CGPoint(x: 0.1, y: 0.875)
    
    public var trueZeroFrame = CGRect.zero
    
    
    override init(image: UIImage?) {
        super.init(image: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
