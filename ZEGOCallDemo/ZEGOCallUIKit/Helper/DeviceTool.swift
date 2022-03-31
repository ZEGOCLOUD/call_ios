//
//  DevicePermissionsManager.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/31.
//

import UIKit

class DeviceTool: NSObject {
    
    static let shared = DeviceTool()

    var cameraPermission: Bool = true
    var micPermission: Bool = true
    
    override init() {
        super.init()
        applicationHasMicAndCameraAccess(nil)
    }
    
    func applicationHasMicAndCameraAccess(_ viewController: UIViewController?) {
        // not determined
        if !AuthorizedCheck.isCameraAuthorizationDetermined(){
            AuthorizedCheck.takeCameraAuthorityStatus { result in
                if result {
                    self.cameraPermission = true
                } else {
                    self.cameraPermission = false
                    if let viewController = viewController {
                        AuthorizedCheck.showCameraUnauthorizedAlert(viewController)
                    }
                }
            }
        } else {
            // determined but not authorized
            if !AuthorizedCheck.isCameraAuthorized() {
                cameraPermission = false
                if let viewController = viewController {
                    AuthorizedCheck.showCameraUnauthorizedAlert(viewController)
                }
            }
        }
        
        // not determined
        if !AuthorizedCheck.isMicrophoneAuthorizationDetermined(){
            AuthorizedCheck.takeMicPhoneAuthorityStatus { result in
                if result {
                    self.micPermission = true
                } else {
                    self.micPermission = false
                    if let viewController = viewController {
                        AuthorizedCheck.showMicrophoneUnauthorizedAlert(viewController)
                    }
                }
            }
        } else {
            // determined but not authorized
            if !AuthorizedCheck.isMicrophoneAuthorized() {
                if let viewController = viewController {
                    AuthorizedCheck.showMicrophoneUnauthorizedAlert(viewController)
                }
                micPermission = false
            }
        }
    }
    
}
