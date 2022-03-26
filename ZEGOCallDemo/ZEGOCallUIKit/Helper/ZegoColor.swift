//
//  ZegoColor.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/24.
//

import Foundation
import UIKit

/// get color with name in Assets
func ZegoColor(_ name: String) -> UIColor {
    var colorName = name
    if colorName.contains("#") {
        colorName = colorName.replacingOccurrences(of: "#", with: "")
    }
    guard let color = UIColor(named: colorName) else {
        return UIColor.white
    }
    return color
}
