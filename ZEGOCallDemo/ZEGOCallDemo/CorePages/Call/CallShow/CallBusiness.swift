//
//  CallUIBusiness.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import UIKit
import ZIM
import ZegoExpressEngine

class CallBusiness: NSObject {
    
    static let shared = CallBusiness()
    
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    var currentCallVC: CallMainVC?
    
    var callKitUserInfo: UserInfo?
    var callKitCallType: CallType = .audio
    
    // MARK: - Private
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(callKitStart), name: Notification.Name("callStart"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callKitEnd), name: Notification.Name("callEnd"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(muteSpeaker), name: Notification.Name("muteSpeaker"), object: nil)
    }
    
    func startCall(_ userInfo: UserInfo, callType: CallType) {
        let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .take)
        currentCallVC = vc
        getCurrentViewController()?.present(vc, animated: true, completion: nil)
    }
    
    private func acceptCall(_ userInfo: UserInfo, callType: CallType, isCallKit: Bool = false) {
//        if isCallKit {
//
//        }
//
//
//        } else {
//            guard let userID = userInfo.userID else { return }
//            RoomManager.shared.userService.responseCall(userID, callType: callType,responseType: .accept) { result in
//                switch result {
//                case .success():
//                    let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .calling)
//                    self.currentCallVC = callVC
//                    if let controller = self.getCurrentViewController() {
//                        controller.present(callVC, animated: true) {
//                            self.startPlayingStream(userID)
//                        }
//                    }
//                case .failure(_):
//                    break
//                }
//            }
//        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension CallBusiness: UserServiceDelegate {
    
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent) {
        
    }
    
    func receiveCall(_ userInfo: UserInfo, type: CallType) {
        if UIApplication.shared.applicationState == .active {
            let callTipView: CallAcceptTipView = CallAcceptTipView.showTipView(type, userInfo: userInfo)
            callTipView.delegate = self
        } else {
            callKitUserInfo = userInfo
            callKitCallType = type
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
            startPlayingStream(userInfo.userID)
        } else {
            RoomManager.shared.userService.endCall(userInfo.userID ?? "", callback: nil)
            vc.dismiss(animated: true, completion: nil)
        }
    }
    
    func receiveEndCall() {
        RoomManager.shared.userService.roomService.leaveRoom { result in
            switch result {
            case .success():
                self.currentCallVC?.dismiss(animated: true, completion: nil)
                let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
                if let uuid = UUID(uuidString: deviceID) {
                    self.appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuuid in
                        
                    })
                }
            case .failure(_):
                break
            }
        }
    }
    
    func startPlayingStream(_ userID: String?) {
        guard let userID = userID else { return }
        if let vc = self.currentCallVC {
            if vc.vcType == .audio {
                RoomManager.shared.userService.micOperation(true, callback: nil)
                self.startPlaying(userID, streamView: nil, type: .audio)
            } else {
                RoomManager.shared.userService.micOperation(true, callback: nil)
                RoomManager.shared.userService.cameraOpen(true, callback: nil)
                self.startPlaying(userID, streamView: vc.mainPreviewView, type: .video)
                self.startPlaying(RoomManager.shared.userService.localUserInfo?.userID, streamView: vc.previewView, type: .video)
            }
            ZegoExpressEngine.shared().muteSpeaker(RoomManager.shared.userService.localUserInfo?.voice ?? true)
        }
    }
    
}

extension CallBusiness: CallAcceptTipViewDelegate {
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
                    let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .calling)
                    self.currentCallVC = callVC
                    if let controller = self.getCurrentViewController() {
                        controller.present(callVC, animated: true) {
                            self.startPlayingStream(userID)
                        }
                    }
                case .failure(_):
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
