//
//  CardView.swift
//  Copyright © 2020 Mithun Das. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class CardView: UIView {
    var cornnerRadius : CGFloat = 8
    var shadowOfSetWidth : CGFloat = 0
    var shadowOfSetHeight : CGFloat = 5
    
    var shadowColour : UIColor = UIColor.black
    var shadowOpacity : CGFloat = 0.2
    
    override func layoutSubviews() {
        layer.cornerRadius = cornnerRadius
        layer.shadowColor = shadowColour.cgColor
        layer.shadowOffset = CGSize(width: shadowOfSetWidth, height: shadowOfSetHeight)
        
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornnerRadius)
        
        layer.shadowPath = shadowPath.cgPath
        
        layer.shadowOpacity = Float(shadowOpacity)
        
    }
}

