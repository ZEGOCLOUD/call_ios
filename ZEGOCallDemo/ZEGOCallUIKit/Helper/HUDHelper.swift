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
    static func showMessage(message:String, doneHandler:@escaping () -> Void) -> Void {
        DispatchQueue.main.async {
            let hud = MKHUDView(frame: UIScreen.main.bounds, theme: .light)
            hud.mode = .text
            hud.detailLabel.font = UIFont.systemFont(ofSize: 15)
            hud.detailText = message
            hud.autoHidden = 2.0
            hud.completionHandle = doneHandler
            hud.show(to: KeyWindow())
        }
    }
    
    /// Display network loading HUD
    static func showNetworkLoading() -> Void {
        DispatchQueue.main.async {
            let hud = MKHUDView(frame: UIScreen.main.bounds, theme: .light)
            hud.mode = .indeterminate
            hud.animationMode = .zoomIn
            hud.accessibilityIdentifier = "NetWorkLoading"
            hud.show(to: KeyWindow())
        }
    }
    
    /// Display network loading with message
    static func showNetworkLoading(_ message: String) {
        DispatchQueue.main.async {
            let hud = MKHUDView(frame: UIScreen.main.bounds, theme: .light)
            hud.accessibilityIdentifier = "NetWorkLoading"
            hud.mode = .indeterminate
            hud.text = message
            hud.textLabel.font = UIFont.systemFont(ofSize: 15)
            hud.show(to: KeyWindow())
        }
    }
    
    /// Display network loading with message on toView
    static func showNetworkLoading(_ message: String, toView: UIView) {
        DispatchQueue.main.async {
            let hud = MKHUDView(frame: toView.bounds, theme: .light)
            hud.accessibilityIdentifier = "NetWorkLoading"
            hud.mode = .indeterminate
            hud.text = message
            hud.textLabel.font = UIFont.systemFont(ofSize: 15)
            hud.show(to: toView)
        }
    }
    
    /// Remove network loading HUD
    static func hideNetworkLoading(_ onView: UIView) {
        DispatchQueue.main.async {
            for subview in onView.subviews {
                if subview is MKHUDView{
                    let hud = subview as! MKHUDView
                    if hud.accessibilityIdentifier == "NetWorkLoading" {
                        hud.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    /// Remove network loading HUD
    static func hideNetworkLoading() -> Void {
        DispatchQueue.main.async {
            for subview in KeyWindow().subviews {
                if subview is MKHUDView {
                    let hud = subview as! MKHUDView
                    if hud.accessibilityIdentifier == "NetWorkLoading" {
                        hud.dismiss(animated: true)
                    }
                }
            }
        }
    }

}
