//
//  MKHUDModelUnit.swift
//  MKHUD
//
//  Created by Jacky on 2021/5/23.
//

import UIKit

extension UIColor {
    
    func darkLike() -> Bool {
        var vRed: CGFloat = 0, vGreen: CGFloat = 0, vBlue: CGFloat = 0, vAlpha: CGFloat = 0
        self.getRed(&vRed, green: &vGreen, blue: &vBlue, alpha: &vAlpha)
        let yValue = 0.299 * vRed + 0.587 * vGreen + 0.114 * vBlue
        // 浅色(<0.75) 深色(>0.75)
        return yValue < 0.75
    }
    
}

extension CGFloat {
    
    var half: CGFloat {
        self * 0.5
    }
    
    var dual: CGFloat {
        self * 2.0
    }
    
}

extension NSLayoutConstraint {
    
    func appendPriority(_ priority: Float) -> NSLayoutConstraint {
        self.priority = UILayoutPriority(priority)
        return self
    }
    
}
