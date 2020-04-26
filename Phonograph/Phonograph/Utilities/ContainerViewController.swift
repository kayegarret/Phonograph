//
//  ContainerViewController.swift
//  TestApplication
//
//  Created by Garret Kaye on 4/12/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit

class ContainerViewController <View:UIView> : UIViewController {
    
    public var container : View {
        get {
            return self.view as! View
        } set {
            self.view = newValue
        }
    }
    
    override var view: UIView! {
        willSet {
            if newValue is View == false {
                fatalError("view type of \(type(of: newValue)) does not match the specified type of \(View.Type.self)")
            }
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func loadView() {
        self.view = View.init(frame: CGRect.zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

