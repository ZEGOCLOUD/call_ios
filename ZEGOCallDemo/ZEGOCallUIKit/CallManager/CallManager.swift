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

protocol CallManagerDelegate: AnyObject {
    func onReceiveCallingUserDisconnected(_ userInfo: UserInfo)
    func onReceiveCallInvite(_ userInfo: UserInfo, type: CallType)
    func onReceiveCallCanceled(_ userInfo: UserInfo)
    func onReceiveCallResponse(_ userInfo: UserInfo, responseType: ResponseType)
    func onReceiveCallTimeOut(_ type: CallTimeoutType)
    func onReceivedCallEnded()
}

class CallManager: NSObject {

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
    
    var enableCallKit = true
    var callKitService: AppleCallKitServiceIMP?
    let localUserInfo: UserInfo? = ServiceManager.shared.userService.localUserInfo
    
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
    
    static let shared = CallManager()
    
    var myUUID: UUID = UUID()
    weak var delegate:CallManagerDelegate?
    
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
        
        ServiceManager.shared.userService.delegate = self
        ServiceManager.shared.callService.delegate = self
        
        callKitService = AppleCallKitServiceIMP()
    }
    
    public func initWithAppID(_ appID: UInt32, callback: RoomCallback?) {
        ServiceManager.shared.initWithAppID(appID: appID, callback: callback)
    }
    
    public func login(_ token: String, callback: RoomCallback?) {
        ServiceManager.shared.userService.login(token, callback: callback)
    }
    
    public func logout(_ callback: RoomCallback?) {
        ServiceManager.shared.userService.logout(callback)
    }
    
    public func getOnlineUserList(_ callback: UserListCallback?)  {
        ServiceManager.shared.userService.getOnlineUserList(callback)
    }
    
    public func uploadLog(_ callback: RoomCallback?) {
        ServiceManager.shared.uploadLog(callback: callback)
    }
    
    public func enableAppleCallKit(_ enable: Bool) {
        enableCallKit = enable
    }
    
    public func callUser(_ userInfo: UserInfo, token: String, callType: CallType, callback: RoomCallback?) {
        if currentCallStatus != .free { return }
        guard let userID = userInfo.userID else { return }
        ServiceManager.shared.callService.callUser(userID, token: token, type: callType) { result in
            if result.isSuccess {
                let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .take)
                self.currentCallVC = vc
                self.currentCallStatus = .waitAccept
                self.currentCallUserInfo = userInfo
                self.getCurrentViewController()?.present(vc, animated: true, completion: nil)
                ServiceManager.shared.deviceService.useFrontCamera(true)
            } else {
                guard let callback = callback else { return }
                callback(result)
            }
        }
    }
    
    
    func acceptCall(_ userInfo: UserInfo, callType: CallType) {
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
                CallManager.shared.audioPlayer?.stop()
                CallManager.shared.currentCallStatus = .free
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
    
    func startPlayingStream(_ userID: String?) {
        guard let userID = userID else { return }
        guard let userRoomInfo = ServiceManager.shared.userService.localUserInfo else { return }
        if let vc = currentCallVC {
            if vc.vcType == .voice {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
                ServiceManager.shared.streamService.startPlaying(userID, streamView: nil)
            } else {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
                ServiceManager.shared.deviceService.enableCamera(userRoomInfo.camera, callback: nil)
                if let mainStreamID = currentCallVC?.mainStreamUserID {
                    ServiceManager.shared.streamService.startPlaying(mainStreamID, streamView: vc.mainPreviewView)
                } else {
                    ServiceManager.shared.streamService.startPlaying(ServiceManager.shared.userService.localUserInfo?.userID, streamView: vc.mainPreviewView)
                }
                if let streamID = currentCallVC?.streamUserID {
                    ServiceManager.shared.streamService.startPlaying(streamID, streamView: vc.previewView)
                } else {
                    ServiceManager.shared.streamService.startPlaying(userID, streamView: vc.previewView)
                }
            }
            ServiceManager.shared.deviceService.enableSpeaker(false)
        } else {
            ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
            ServiceManager.shared.streamService.startPlaying(userID, streamView: nil)
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
