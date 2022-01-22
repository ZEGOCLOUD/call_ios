//
//  CallUIBusiness.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import UIKit
import ZIM
import ZegoExpressEngine

enum callStatus: Int {
    case free
    case wait
    case calling
}

class CallBusiness: NSObject {
    
    static let shared = CallBusiness()

    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    var currentCallVC: CallMainVC?
    var currentCallUserInfo: UserInfo?
    var callKitCallType: CallType = .audio
    var currentCallStatus: callStatus = .free
    var appIsActive: Bool = true
    var currentTipView: CallAcceptTipView?
    
    // MARK: - Private
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(callKitStart), name: Notification.Name("callStart"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callKitEnd), name: Notification.Name("callEnd"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(muteSpeaker), name: Notification.Name("muteSpeaker"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    
    func startCall(_ userInfo: UserInfo, callType: CallType) {
        let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .take)
        currentCallVC = vc
        currentCallStatus = .wait
        currentCallUserInfo = userInfo
        getCurrentViewController()?.present(vc, animated: true, completion: nil)
    }
    
    
    private func acceptCall(_ userInfo: UserInfo, callType: CallType) {
        guard let userID = userInfo.userID else { return }
        RoomManager.shared.userService.responseCall(userID, callType: callType,responseType: .accept) { result in
            switch result {
            case .success():
                let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .calling)
                self.currentCallVC = callVC
                self.currentCallStatus = .calling
                self.currentCallUserInfo = userInfo
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
    
    func endCall(_ userID: String, callType: CallType) {
        if currentCallUserInfo?.userID == userID {
            currentCallStatus = .free
            currentCallUserInfo = nil
        }
        let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
        if let uuid = UUID(uuidString: deviceID) {
            appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuid in
                
            })
        }
        RoomManager.shared.userService.responseCall(userID, callType: callType, responseType: .reject, callback: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension CallBusiness: UserServiceDelegate {
    
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent) {
        
    }
    
    func receiveCall(_ userInfo: UserInfo, type: CallType) {
        if currentCallStatus == .calling || currentCallStatus == .wait {
            guard let userID = userInfo.userID else { return }
            if let currentCallUserInfo = currentCallUserInfo {
                if userID != currentCallUserInfo.userID {
                    endCall(userID, callType: type)
                }
            }
            return
        }
        
        currentCallStatus = .wait
        currentCallUserInfo = userInfo
        if UIApplication.shared.applicationState == .active {
            let callTipView: CallAcceptTipView = CallAcceptTipView.showTipView(type, userInfo: userInfo)
            currentTipView = callTipView
            callTipView.delegate = self
        } else {
            callKitCallType = type
            let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
            if let uuid = UUID(uuidString: deviceID) {
                self.appDelegate.displayIncomingCall(uuid: uuid, handle: "2222")
            }
        }
    }
    
    func receiveCancelCall(_ userInfo: UserInfo) {
        currentCallStatus = .free
        currentCallUserInfo = nil
        guard let currentTipView = currentTipView else { return }
        currentTipView.removeFromSuperview()
        let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
        if let uuid = UUID(uuidString: deviceID) {
            appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuid in
                
            })
        }
    }
    
    func receiveCallResponse(_ userInfo: UserInfo, responseType: CallResponseType) {
        guard let vc = self.currentCallVC else { return }
        if responseType == .accept {
            currentCallUserInfo = userInfo
            currentCallStatus = .calling
            vc.updateCallType(vc.vcType, userInfo: userInfo, status: .calling)
            startPlayingStream(userInfo.userID)
        } else {
            currentCallUserInfo = nil
            currentCallStatus = .free
            RoomManager.shared.userService.endCall(userInfo.userID ?? "") { result in
                if result.isSuccess {
                    HUDHelper.showMessage(message: "Decline")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        vc.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func receiveEndCall(_ userInfo: UserInfo) {
        if userInfo.userID != currentCallUserInfo?.userID {
            return
        }
        currentCallUserInfo = nil
        RoomManager.shared.userService.roomService.leaveRoom { result in
            switch result {
            case .success():
                self.currentCallStatus = .free
                HUDHelper.showMessage(message: "complete")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
                    if let uuid = UUID(uuidString: deviceID) {
                        self.appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuid in
                            
                        })
                    }
//                    let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
//                    if let uuid = UUID(uuidString: deviceID) {
//                        self.appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuuid in
//
//                        })
//                    }
                    self.currentCallVC?.dismiss(animated: true, completion: nil)
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
            endCall(userID, callType: callType)
        }
        currentTipView = nil
    }
    
    func tipViewAcceptCall(_ userInfo: UserInfo, callType: CallType) {
        acceptCall(userInfo, callType: callType)
        currentTipView = nil
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
