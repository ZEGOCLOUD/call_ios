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
    case waitAccept
    case calling
}

class CallBusiness: NSObject {

    var currentCallVC: CallMainVC?
    var currentCallUserInfo: UserInfo?
    var callKitCallType: CallType = .audio
    var currentCallStatus: callStatus = .free
    var appIsActive: Bool = true
    var currentTipView: CallAcceptTipView?
    let timer = ZegoTimer(1000)
    var startTimeIdentify: Int = 0
    
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
    
    lazy var myUUID: UUID = {
        let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
        if let uuid = UUID(uuidString: deviceID) {
            return uuid
        }
        return UUID()
    }()
    
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
        currentCallStatus = .waitAccept
        currentCallUserInfo = userInfo
        getCurrentViewController()?.present(vc, animated: true, completion: nil)
        RoomManager.shared.userService.useFrontCamera(true)
    }
    
    
    private func acceptCall(_ userInfo: UserInfo, callType: CallType) {
        guard let userID = userInfo.userID else { return }
        let rtcToken = AppToken.getRtcToken(withRoomID: userID)
        guard let rtcToken = rtcToken else { return }
        RoomManager.shared.userService.responseCall(userID, token: rtcToken, responseType:.accept) { result in
            switch result {
            case .success():
                self.audioPlayer?.stop()
                let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .calling)
                self.currentCallVC = callVC
                self.currentCallStatus = .calling
                self.currentCallUserInfo = userInfo
                if let controller = self.getCurrentViewController() {
                    controller.present(callVC, animated: true) {
                        RoomManager.shared.userService.useFrontCamera(true)
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
        endSystemCall()
        let rtcToken = AppToken.getRtcToken(withRoomID: userID)
        guard let rtcToken = rtcToken else { return }
        RoomManager.shared.userService.responseCall(userID, token: rtcToken, responseType: .reject, callback: nil)
    }
    
    func closeCallVC() {
        guard let currentCallVC = currentCallVC else { return }
        currentCallVC.dismiss(animated: true, completion: {
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
    
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent) {
        if state == .disconnected || state == .connecting || state == .reconnecting {
            if let currentCallVC = currentCallVC {
                currentCallVC.callQualityChange(currentCallVC.netWorkStatus, connectedStatus: .disConnected)
            }
        } else {
            if let currentCallVC = currentCallVC {
                currentCallVC.callQualityChange(currentCallVC.netWorkStatus, connectedStatus: .connected)
            }
        }
    }
    
    
    func receiveCall(_ userInfo: UserInfo, type: CallType) {
        if currentCallStatus == .calling || currentCallStatus == .wait || currentCallStatus == .waitAccept {
            guard let userID = userInfo.userID else { return }
            if let currentCallUserInfo = currentCallUserInfo {
                if userID != currentCallUserInfo.userID {
                    endCall(userID, callType: type)
                }
            }
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
            self.appDelegate.displayIncomingCall(uuid: myUUID, handle:"" , hasVideo: type == .video)
        }
    }
    
    func receiveCancelCall(_ userInfo: UserInfo, type: CancelType) {
        if (currentCallStatus == .calling || currentCallStatus == .wait) && userInfo.userID != currentCallUserInfo?.userID {
            return
        }
        currentCallStatus = .free
        currentCallUserInfo = nil
        endSystemCall()
        audioPlayer?.stop()
        if let currentTipView = currentTipView {
            currentTipView.removeFromSuperview()
        }
        guard let currentCallVC = currentCallVC else { return }
        if type == .intent {
            currentCallVC.changeCallStatusText(.canceled)
        } else {
            currentCallVC.changeCallStatusText(.miss)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            currentCallVC.dismiss(animated: true, completion: nil)
        }
    }
    
    func receiveCallResponse(_ userInfo: UserInfo, responseType: CallResponseType) {
        audioPlayer?.stop()
        guard let vc = self.currentCallVC else { return }
        if responseType == .accept {
            if !appIsActive {
                if let currentCallVC = currentCallVC,
                   let userID = userInfo.userID {
                    if currentCallStatus == .waitAccept {
                        endCall(userID, callType: currentCallVC.vcType)
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
            RoomManager.shared.userService.endCall() { result in
                if result.isSuccess {
                    self.currentCallVC?.changeCallStatusText(.decline)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.closeCallVC()
                    }
                }
            }
        }
    }
    
    func receiveEndCall() {
        audioPlayer?.stop()
        currentCallUserInfo = nil
        RoomManager.shared.userService.roomService.leaveRoom { result in
            switch result {
            case .success():
                self.currentCallStatus = .free
                self.currentCallVC?.changeCallStatusText(.completed)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.endSystemCall()
                    self.closeCallVC()
                }
            case .failure(_):
                break
            }
        }
    }
    
    func startPlayingStream(_ userID: String?) {
        guard let userID = userID else { return }
        if let vc = currentCallVC {
            if let userRoomInfo = RoomManager.shared.userService.localUserRoomInfo {
                if vc.vcType == .audio {
                    RoomManager.shared.userService.micOperation(userRoomInfo.mic, callback: nil)
                    RoomManager.shared.userService.startPlaying(userID, streamView: nil, type: .audio)
                } else {
                    RoomManager.shared.userService.micOperation(userRoomInfo.mic, callback: nil)
                    RoomManager.shared.userService.cameraOpen(userRoomInfo.camera, callback: nil)
                    if let mainStreamID = currentCallVC?.mainStreamUserID {
                        RoomManager.shared.userService.startPlaying(mainStreamID, streamView: vc.mainPreviewView, type: .video)
                    } else {
                        RoomManager.shared.userService.startPlaying(RoomManager.shared.userService.localUserInfo?.userID, streamView: vc.mainPreviewView, type: .video)
                    }
                    if let streamID = currentCallVC?.streamUserID {
                        RoomManager.shared.userService.startPlaying(streamID, streamView: vc.previewView, type: .video)
                    } else {
                        RoomManager.shared.userService.startPlaying(userID, streamView: vc.previewView, type: .video)
                    }
                }
                RoomManager.shared.userService.enableSpeaker(RoomManager.shared.userService.localUserRoomInfo?.voice ?? true)
            }
        }
    }
    
    func userInfoUpdate(_ userInfo: UserInfo) {
        currentCallVC?.userRoomInfoUpdate(userInfo)
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
            endCall(userID, callType: callType)
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
