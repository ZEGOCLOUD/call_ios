//
//  MKHUDExtensions.swift
//  MKHUD
//
//  Created by spring on 2021/5/31.
//

import UIKit

public extension UIView {
    
    @discardableResult
    func showMKHUDIndicator(_ text: String = "", theme: MKHUDTheme = .dark) -> MKHUDView {
        let hub = MKHUDView(frame: self.bounds, theme: theme)
        hub.mode = .indeterminate
        hub.text = text
        hub.animationMode = .zoomIn
        hub.show(to: self)
        return hub
    }
    
    @discardableResult
    func showMKHUDText(_ text: String = "", detailText: String = "", autoHidden: TimeInterval = 2.0, theme: MKHUDTheme = .dark) -> MKHUDView {
        let hub = MKHUDView(frame: self.bounds, theme: theme)
        hub.mode = .text
        hub.text = text
        hub.detailText = detailText
        hub.autoHidden = autoHidden
        hub.animationMode = .zoomIn
        hub.show(to: self)
        return hub
    }
    
    func hideMKHUD(animated: Bool = true) {
        MKHUDView.hideHUDForView(view: self, animated: animated)
    }
    
}
