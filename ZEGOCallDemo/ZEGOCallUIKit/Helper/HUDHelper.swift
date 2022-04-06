//
//  HUDHelper.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by zego on 2021/12/15.
//

import UIKit

class HUDHelper: NSObject {
    
    /// Display a message
    /// - Parameter message: message content
    static func showMessage(message:String) -> Void {
        HUDHelper.showMessage(message: message) {
        }
    }
    
    
    /// Display a message
    /// - Parameters:
    ///   - message: message content
    ///   - doneHandler: done callback
    static func showMessage(message:String,doneHandler:@escaping () -> Void) -> Void {
        DispatchQueue.main.async {
            let hud:MBProgressHUD = MBProgressHUD.showAdded(to: KeyWindow(), animated: true)
            hud.mode = .text
            hud.detailsLabel.text = message
            hud.detailsLabel.font = UIFont.systemFont(ofSize: 15)
            hud.hide(animated: true, afterDelay: 2.0)
            hud.completionBlock = doneHandler
        }
    }
    
    /// Display network loading HUD
    static func showNetworkLoading() -> Void {
        DispatchQueue.main.async {
            let hud: MBProgressHUD = MBProgressHUD.showAdded(to: KeyWindow(), animated: true)
            hud.accessibilityIdentifier = "NetWorkLoading"
        }
    }
    
    /// Display network loading with message
    static func showNetworkLoading(_ message: String) {
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: KeyWindow(), animated: true)
            hud.accessibilityIdentifier = "NetWorkLoading"
            hud.mode = .text
            hud.detailsLabel.text = message
            hud.detailsLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    
    /// Remove network loading HUD
    static func hideNetworkLoading() -> Void {
        DispatchQueue.main.async {
            for subview in KeyWindow().subviews {
                if subview is MBProgressHUD{
                    let hud:MBProgressHUD = subview as! MBProgressHUD
                    if hud.accessibilityIdentifier == "NetWorkLoading" {
                        hud.removeFromSuperViewOnHide = true
                        hud.hide(animated: true)
                    }
                }
            }
        }
    }

}
