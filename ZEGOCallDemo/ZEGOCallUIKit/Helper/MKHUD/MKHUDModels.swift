//
//  MKHUDConfigurations.swift
//  MKHUD
//
//  Created by Jacky on 2021/5/23.
//

import UIKit

public enum MKHUDMode {
    case text
    case indeterminate
    case determinate
    case bar
    case custom
}

public enum MKHUDAnimationMode {
    case none
    case zoomIn
    case zoomOut
}

public enum MKHUDBackgroundStyle {
    case solid
    case blur
}

public typealias MKHUDCompletionHandle = () -> Void

public struct MKHUDTheme {
    var frontgroundColor: UIColor!
    var backgroundColor: UIColor!
    
    public init(_ frontgroundColor: UIColor, _ backgroundColor: UIColor) {
        self.frontgroundColor = frontgroundColor
        self.backgroundColor = backgroundColor
    }
    
    public static var light: MKHUDTheme {
        MKHUDTheme(UIColor(white: 0, alpha: 0.95), UIColor(white: 0.95, alpha: 1))
    }
    
    public static var dark: MKHUDTheme {
        MKHUDTheme(UIColor(white: 1, alpha: 0.95), UIColor(white: 0, alpha: 0.85))
    }
}

public struct MKHUDButtonConfig {
    
    var title: String?
    var action: ((MKHUDView) -> Void)?
    
    public init(title: String, action: @escaping ((MKHUDView) -> Void)) {
        self.title = title
        self.action = action
    }
    
}
