//
//  CallUIBusiness.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import UIKit
import ZIM

class CallUIBusiness: NSObject {
    
    static let shared = CallUIBusiness()
    
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    var currentCallVC: CallMainVC?
    
    // MARK: - Private
    private override init() {
        super.init()
    }
    
    func startCall(_ userInfo: UserInfo, callType: CallType) {
        let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .take)
        currentCallVC = vc
        getCurrentViewController()?.present(vc, animated: true, completion: nil)
    }

}

extension CallUIBusiness: UserServiceDelegate {
    
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent) {
        
    }
    
    func receiveCall(_ userInfo: UserInfo, type: CallType) {
        if UIApplication.shared.applicationState == .active {
            let callTipView: CallAcceptTipView = CallAcceptTipView.showTipView(.audio, userInfo: userInfo)
            callTipView.delegate = self
        } else {
            let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
            if let uuid = UUID(uuidString: deviceID) {
                self.appDelegate.displayIncomingCall(uuid: uuid, handle: "2222")
            }
        }
    }
    
    func receiveCancelCall(_ userInfo: UserInfo) {
        
    }
    
    func receiveCallResponse(_ userInfo: UserInfo, responseType: CallResponseType) {
        guard let vc = self.currentCallVC else { return }
        if responseType == .accept {
            vc.updateCallType(vc.vcType, userInfo: userInfo, status: .calling)
        } else {
            RoomManager.shared.userService.endCall(userInfo.userID ?? "", callback: nil)
            vc.dismiss(animated: true, completion: nil)
        }
    }
    
    func receiveEndCall() {
        
    }
}

extension CallUIBusiness: CallAcceptTipViewDelegate {
    func tipViewDeclineCall(_ userInfo: UserInfo, callType: CallType) {
        if let userID = userInfo.userID {
            RoomManager.shared.userService.responseCall(userID, callType: callType, responseType: .reject, callback: nil)
        }
    }
    
    func tipViewAcceptCall(_ userInfo: UserInfo, callType: CallType) {
        if let userID = userInfo.userID {
            RoomManager.shared.userService.responseCall(userID, callType: callType,responseType: .accept) { result in
                switch result {
                case .success():
                    let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .accept)
                    self.currentCallVC = callVC
                    callVC.statusType = .calling
                    if let controller = self.getCurrentViewController() {
                        controller.present(callVC, animated: true, completion: nil)
                    }
                case .failure(let code):
                    break
                }
                
            }
        }
    }
    
    func getCurrentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return getCurrentViewController(base: nav.visibleViewController)
            }
            if let tab = base as? UITabBarController {
                return getCurrentViewController(base: tab.selectedViewController)
            }
            if let presented = base?.presentedViewController {
                return getCurrentViewController(base: presented)
            }
            return base
        }
    
    
    
}
