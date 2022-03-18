//
//  CallUIBusiness.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import UIKit
import ZegoExpressEngine

enum callStatus: Int {
    case free
    case wait
    case waitAccept
    case calling
}

class CallBusiness: NSObject {

    var currentCallVC: CallMainVC?
    var currentCallUserInfo: UserInfo?
    var callKitCallType: CallType = .voice
    var currentCallStatus: callStatus = .free
    var appIsActive: Bool = true
    var currentTipView: CallAcceptTipView?
    let timer = ZegoTimer(1000)
    var startTimeIdentify: Int = 0
    var startCallTime: Int = 0
    var otherUserRoomInfo: UserInfo?
    var isConnected: Bool = true
    
    lazy var audioPlayer: AVAudioPlayer? = {
        let path = Bundle.main.path(forResource: "CallRing", ofType: "wav")!
        let url = URL(fileURLWithPath: path)
        do {
            let player =  try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            return player
        } catch {
          // can't load file
            return nil
        }
    }()
    
    static let shared = CallBusiness()
    
    let appDelegate = (UIApplication.shared.delegate) as! AppDelegate
    
    var myUUID: UUID = UUID()
    
    // MARK: - Private
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(callKitStart), name: Notification.Name(CALL_NOTI_START), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callKitEnd), name: Notification.Name(CALL_NOTI_END), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(muteSpeaker(notif:)), name: Notification.Name(CALL_NOTI_MUTE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        timer.setEventHandler {
            let currentTime = Int(Date().timeIntervalSince1970)
            if self.currentCallStatus == .wait && currentTime - self.startTimeIdentify > 60 {
                CallAcceptTipView.dismiss()
                self.currentCallStatus = .free
                self.currentCallUserInfo = nil
                self.audioPlayer?.stop()
                self.endSystemCall()
            }
        }
        timer.start()
    }
    
    func startCall(_ userInfo: UserInfo, callType: CallType) {
        if currentCallStatus != .free {
            ServiceManager.shared.callService.endCall(nil)
            return
        }
        let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .take)
        currentCallVC = vc
        currentCallStatus = .waitAccept
        currentCallUserInfo = userInfo
        getCurrentViewController()?.present(vc, animated: true, completion: nil)
        ServiceManager.shared.deviceService.useFrontCamera(true)
    }
    
    
    private func acceptCall(_ userInfo: UserInfo, callType: CallType) {
        guard let userID = userInfo.userID else { return }
        let rtcToken = AppToken.getRtcToken(withRoomID: userID)
        guard let rtcToken = rtcToken else { return }
        ServiceManager.shared.callService.respondCall(userID, token: rtcToken, responseType:.accept) { result in
            switch result {
            case .success():
                self.audioPlayer?.stop()
                let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .calling)
                callVC.otherUserRoomInfo = self.otherUserRoomInfo
                self.currentCallVC = callVC
                self.currentCallStatus = .calling
                self.currentCallUserInfo = userInfo
                if let controller = self.getCurrentViewController() {
                    controller.present(callVC, animated: true) {
                        ServiceManager.shared.deviceService.useFrontCamera(true)
                        self.startPlayingStream(userID)
                    }
                }
            case .failure(_):
                break
            }
        }
    }
    
    func refusedCall(_ userID: String) {
        if currentCallUserInfo?.userID == userID {
            currentCallStatus = .free
            currentCallUserInfo = nil
            otherUserRoomInfo = nil
        }
        let rtcToken = AppToken.getRtcToken(withRoomID: userID)
        guard let rtcToken = rtcToken else { return }
        ServiceManager.shared.callService.respondCall(userID, token: rtcToken, responseType: .decline, callback: nil)
    }
    
    func endCall(_ userID: String) {
        if currentCallUserInfo?.userID == userID {
            currentCallStatus = .free
            currentCallUserInfo = nil
            otherUserRoomInfo = nil
        }
        endSystemCall()
        if ServiceManager.shared.callService.status == .calling {
            ServiceManager.shared.callService.endCall(nil)
        } else {
            refusedCall(userID)
        }
    }
    
    func cancelCall(_ userID: String, callType: CallType, isTimeout: Bool = false) {
        ServiceManager.shared.callService.cancelCall(userID: userID, cancelType: .intent) { result in
            switch result {
            case .success():
                CallBusiness.shared.audioPlayer?.stop()
                CallBusiness.shared.currentCallStatus = .free
                if isTimeout {
                    self.currentCallVC?.changeCallStatusText(.miss)
                } else {
                    self.currentCallVC?.changeCallStatusText(.canceled)
                }
                self.currentCallVC?.callDelayDismiss()
            case .failure(let error):
                let message = String(format: ZGLocalizedString("cancel_call_failed"), error.code)
                TipView.showWarn(message)
            }
        }
    }
    
    func closeCallVC() {
        guard let currentCallVC = currentCallVC else { return }
        currentCallVC.resetTime()
        currentCallVC.dismiss(animated: true, completion: {
            UIApplication.shared.isIdleTimerDisabled = false
            self.currentCallVC?.statusType = .completed
            self.currentCallVC = nil
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension CallBusiness: UserServiceDelegate {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel) {
        if userID == localUserID {
            if let currentCallVC = currentCallVC {
                currentCallVC.callQualityChange(setNetWorkQuality(upstreamQuality: upstreamQuality), connectedStatus: currentCallVC.callConnected)
            }
        }
    }
    
    private func setNetWorkQuality(upstreamQuality: ZegoStreamQualityLevel) -> NetWorkStatus {
        if upstreamQuality == .excellent || upstreamQuality == .good {
            return .good
        } else if upstreamQuality == .medium {
            return.middle
        } else if upstreamQuality == .unknown {
            return .unknow
        } else {
            return .low
        }
    }
    
//    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent) {
//        if state == .connected {
//            isConnected = true
//            currentTipView?.isUserInteractionEnabled = true
//            guard let currentCallVC = currentCallVC else { return }
//            currentCallVC.callQualityChange(currentCallVC.netWorkStatus, connectedStatus: .connected)
//        } else {
//            isConnected = false
//            currentTipView?.isUserInteractionEnabled = false
//            guard let currentCallVC = currentCallVC else { return }
//            currentCallVC.callQualityChange(currentCallVC.netWorkStatus, connectedStatus: .disConnected)
//        }
//    }
    
    
    func onReceiveCallInvite(_ userInfo: UserInfo, type: CallType) {
        if currentCallStatus == .calling || currentCallStatus == .wait || currentCallStatus == .waitAccept {
            guard let userID = userInfo.userID else { return }
            refusedCall(userID)
            return
        }
        startTimeIdentify = Int(Date().timeIntervalSince1970)
        currentCallStatus = .wait
        currentCallUserInfo = userInfo
        callKitCallType = type
        if UIApplication.shared.applicationState == .active {
            let callTipView: CallAcceptTipView = CallAcceptTipView.showTipView(type, userInfo: userInfo)
            currentTipView = callTipView
            callTipView.delegate = self
            audioPlayer?.play()
        } else {
            let uuid = UUID()
            myUUID = uuid
            self.appDelegate.displayIncomingCall(uuid: uuid, handle:"" , hasVideo: type == .video)
        }
    }
    
    func onReceiveCallCanceled(_ userInfo: UserInfo, type: CancelType) {
        if (currentCallStatus == .calling || currentCallStatus == .wait) && userInfo.userID != currentCallUserInfo?.userID {
            return
        }
        
        currentCallStatus = .free
        currentCallUserInfo = nil
        endSystemCall()
        audioPlayer?.stop()
        CallAcceptTipView.dismiss()
        guard let currentCallVC = currentCallVC else { return }
        if type == .intent {
            currentCallVC.changeCallStatusText(.canceled)
        } else {
            currentCallVC.changeCallStatusText(.miss)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.shared.isIdleTimerDisabled = false
            currentCallVC.statusType = .completed
            currentCallVC.resetTime()
            currentCallVC.dismiss(animated: true, completion: nil)
        }
    }
    
    func onReceiveCallResponse(_ userInfo: UserInfo, responseType: ResponseType) {
        guard let vc = self.currentCallVC else { return }
        if responseType == .accept {
            if !appIsActive {
                if let userID = userInfo.userID {
                    if currentCallStatus == .waitAccept {
                        endCall(userID)
                        closeCallVC()
                    }
                }
                return
            }
            currentCallUserInfo = userInfo
            currentCallStatus = .calling
            vc.updateCallType(vc.vcType, userInfo: userInfo, status: .calling)
            startPlayingStream(userInfo.userID)
        } else {
            currentCallUserInfo = nil
            currentCallStatus = .free
            ServiceManager.shared.callService.endCall() { result in
                if result.isSuccess {
                    self.currentCallVC?.changeCallStatusText(.decline)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.closeCallVC()
                    }
                }
            }
        }
    }
    
    func onReceiveCallEnded() {
        audioPlayer?.stop()
        if currentCallStatus != .calling {
            currentCallVC?.changeCallStatusText(.completed,showHud: false)
        } else {
            currentCallVC?.changeCallStatusText(.completed,showHud: true)
        }
        currentCallUserInfo = nil
        self.currentCallStatus = .free
        self.otherUserRoomInfo = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.endSystemCall()
            self.closeCallVC()
        }
    }
    
    func startPlayingStream(_ userID: String?) {
        guard let userID = userID else { return }
        guard let userRoomInfo = ServiceManager.shared.userService.localUserInfo else { return }
        if let vc = currentCallVC {
            if vc.vcType == .voice {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
                ServiceManager.shared.deviceService.startPlaying(userID, streamView: nil)
            } else {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
                ServiceManager.shared.deviceService.enableCamera(userRoomInfo.camera, callback: nil)
                if let mainStreamID = currentCallVC?.mainStreamUserID {
                    ServiceManager.shared.deviceService.startPlaying(mainStreamID, streamView: vc.mainPreviewView)
                } else {
                    ServiceManager.shared.deviceService.startPlaying(ServiceManager.shared.userService.localUserInfo?.userID, streamView: vc.mainPreviewView)
                }
                if let streamID = currentCallVC?.streamUserID {
                    ServiceManager.shared.deviceService.startPlaying(streamID, streamView: vc.previewView)
                } else {
                    ServiceManager.shared.deviceService.startPlaying(userID, streamView: vc.previewView)
                }
            }
            ServiceManager.shared.deviceService.enableSpeaker(ServiceManager.shared.userService.localUserInfo?.voice ?? false)
        } else {
            ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
            ServiceManager.shared.deviceService.startPlaying(userID, streamView: nil)
        }
    }
    
    func onUserInfoUpdate(_ userInfo: UserInfo) {
        if userInfo.userID != localUserID {
            otherUserRoomInfo = userInfo
        }
        guard let currentCallVC = currentCallVC else { return }
        currentCallVC.userRoomInfoUpdate(userInfo)
        
    }
}

extension CallBusiness: CallAcceptTipViewDelegate {
    func tipViewDidClik(_ userInfo: UserInfo, callType: CallType) {
        if let currentCallVC = currentCallVC {
            currentCallVC.updateCallType(callType, userInfo: userInfo, status: .accept)
            getCurrentViewController()?.present(currentCallVC, animated: true, completion: nil)
        } else {
            let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .accept)
            currentCallVC = vc
            currentCallStatus = .wait
            currentCallUserInfo = userInfo
            getCurrentViewController()?.present(vc, animated: true, completion: nil)
        }
    }
    
    func tipViewDeclineCall(_ userInfo: UserInfo, callType: CallType) {
        if let userID = userInfo.userID {
            refusedCall(userID)
        }
        audioPlayer?.stop()
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
