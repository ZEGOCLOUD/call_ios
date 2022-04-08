//
//  CustomButton.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/4/8.
//

import UIKit

class CustomButton: UIButton {
    
    var widthHot: CGFloat = 50
    var heightHot: CGFloat = 50
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
        var bounds: CGRect = self.bounds
        let widthDelta: CGFloat = max(widthHot, 0)
        let heightDelta: CGFloat = max(heightHot, 0);
        bounds = bounds.insetBy(dx: -0.5 * widthDelta, dy: -0.5 * heightDelta)
        return bounds.contains(point)
    }

}
