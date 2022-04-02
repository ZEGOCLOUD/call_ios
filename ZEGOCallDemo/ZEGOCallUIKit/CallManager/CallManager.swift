//
//  CallUIBusiness.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import UIKit
import ZegoExpressEngine

class CallManager: NSObject, CallManagerInterface {
    
    static var shared: CallManager! = CallManager()
    weak var delegate: CallManagerDelegate?
    var currentCallStatus: callStatus! = .free
    var token: String?
    var localUserInfo: UserInfo? {
        get {
            ServiceManager.shared.userService.localUserInfo
        }
    }
    
    var currentCallVC: CallMainVC?
    var currentCallUserInfo: UserInfo?
    var callKitCallType: CallType = .voice
    var appIsActive: Bool = true
    var currentTipView: CallAcceptTipView?
    var otherUserRoomInfo: UserInfo?
    var callKitService: AppleCallKitServiceIMP?
    var myUUID: UUID = UUID()
    
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
    
    lazy var callTimeManager: CallTimeManager = {
        let manager = CallTimeManager()
        manager.delegate = self
        return manager
    }()
    
    lazy var minmizedManager: MinimizedDisplayManager = {
        let manager = MinimizedDisplayManager()
        manager.delegate = self
        return manager
    }()
    
    // MARK: - Private
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(callKitStart), name: Notification.Name(CALL_NOTI_START), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callKitEnd), name: Notification.Name(CALL_NOTI_END), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(muteSpeaker(notif:)), name: Notification.Name(CALL_NOTI_MUTE), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        ServiceManager.shared.userService.delegate = self
        ServiceManager.shared.callService.delegate = self
        ServiceManager.shared.deviceService.delegate = self
        
        callKitService = AppleCallKitServiceIMP()
        callKitService?.providerDelegate = ProviderDelegate()
    }
    
    func initWithAppID(_ appID: UInt32, callback: ZegoCallback?) {
        ServiceManager.shared.initWithAppID(appID: appID, callback: callback)
    }
    
    func getToken(_ userID: String, _ effectiveTimeInSeconds: Int, callback: RequestCallback?) {
        ServiceManager.shared.userService.getToken(userID, effectiveTimeInSeconds, callback: callback)
    }
    
    func setLocalUser(_ userID: String, userName: String) {
        ServiceManager.shared.userService.setLocalUser(userID, userName: userName)
    }
    
    func resetCallData() {
        switch currentCallStatus {
        case .free:
            break
        case .wait:
            CallAcceptTipView.dismiss()
            currentCallStatus = .free
            currentCallUserInfo = nil
            audioPlayer?.stop()
            endSystemCall()
            closeCallVC()
        case .waitAccept:
            guard let userID = currentCallUserInfo?.userID else { return }
            guard let currentCallVC = currentCallVC else { return }
            cancelCall(userID, callType: currentCallVC.vcType)
        case .calling:
            guard let userID = currentCallUserInfo?.userID else { return }
            endCall(userID)
            closeCallVC()
        case .none:
            break
        }
    }
        
    public func uploadLog(_ callback: ZegoCallback?) {
        ServiceManager.shared.uploadLog(callback: callback)
    }
    
    func callUser(_ userInfo: UserInfo, token: String, callType: CallType, callback: ZegoCallback?) {
        if currentCallStatus != .free { return }
        self.currentCallStatus = .waitAccept
        resetDeviceConfig()
        ServiceManager.shared.callService.callUser(userInfo, token: token, type: callType) { result in
            switch result {
            case .success():
                let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .take)
                self.currentCallVC = vc
                self.currentCallUserInfo = userInfo
                self.getCurrentViewController()?.present(vc, animated: true, completion: nil)
                ServiceManager.shared.deviceService.useFrontCamera(true)
            case .failure(_):
                self.currentCallStatus = .free
                guard let callback = callback else { return }
                callback(result)
            }
        }
    }
    
    
    func acceptCall(_ userInfo: UserInfo, callType: CallType, presentVC:Bool = true) {
        guard let userID = userInfo.userID else { return }
        guard let token = token else {
            print("call token is not exists")
            return
        }
        resetDeviceConfig()
        ServiceManager.shared.callService.acceptCall(token) { result in
            switch result {
            case .success():
                self.audioPlayer?.stop()
                self.currentCallStatus = .calling
                self.otherUserRoomInfo = userInfo
                self.currentCallUserInfo = userInfo
                self.callTimeManager.callStart()
                self.minmizedManager.currentStatus = .calling
                ServiceManager.shared.deviceService.useFrontCamera(true)
                if presentVC {
                    let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .calling)
                    callVC.otherUserRoomInfo = self.otherUserRoomInfo
                    self.currentCallVC = callVC
                    if let controller = self.getCurrentViewController() {
                        controller.present(callVC, animated: true) {
                            self.startPlayingStream(userID)
                        }
                    }
                } else {
                    guard let currentCallVC = self.currentCallVC else { return }
                    currentCallVC.otherUserRoomInfo = self.otherUserRoomInfo
                    currentCallVC.updateCallType(currentCallVC.vcType, userInfo: userInfo, status: .calling)
                    self.startPlayingStream(userID)
                }
            case .failure(_):
                self.currentCallStatus = .free
                if !presentVC {
                    self.currentCallVC?.changeCallStatusText(.decline)
                    self.currentCallVC?.callDelayDismiss()
                }
                break
            }
        }
    }
    
    func declineCall(_ userID: String, callID: String?, type: DeclineType) {
        if currentCallUserInfo?.userID == userID {
            currentCallStatus = .free
            currentCallUserInfo = nil
            otherUserRoomInfo = nil
        }
        audioPlayer?.stop()
        ServiceManager.shared.callService.declineCall(userID, callID: callID, type: type, callback: nil)
    }
    
    func endCall(_ userID: String) {
        if ServiceManager.shared.callService.status == .calling {
            minmizedManager.updateCallStatus(status: .end, userInfo: currentCallUserInfo)
            ServiceManager.shared.callService.endCall(nil)
        } else {
            minmizedManager.updateCallStatus(status: .decline, userInfo: currentCallUserInfo)
            declineCall(userID, callID: nil, type: .decline)
        }
        minmizedManager.dismissCallMinView()
        if currentCallUserInfo?.userID == userID {
            currentCallStatus = .free
            currentCallUserInfo = nil
            otherUserRoomInfo = nil
        }
        endSystemCall()
    }
    
    func cancelCall(_ userID: String, callType: CallType) {
        audioPlayer?.stop()
        currentCallStatus = .free
        currentCallVC?.changeCallStatusText(.canceled)
        currentCallVC?.callDelayDismiss()
        minmizedManager.dismissCallMinView()
        ServiceManager.shared.callService.cancelCall(userID: userID, callback: nil)
    }
    
    func resetDeviceConfig() {
        ServiceManager.shared.userService.localUserInfo?.mic = true
        ServiceManager.shared.userService.localUserInfo?.camera = true
        ServiceManager.shared.deviceService.resetDeviceConfig()
    }
    
    func startPlayingStream(_ userID: String?) {
        guard let userID = userID else { return }
        guard let userRoomInfo = ServiceManager.shared.userService.localUserInfo else { return }
        
        if let vc = currentCallVC {
            if vc.vcType == .voice {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
                ServiceManager.shared.streamService.startPlaying(userID, streamView: nil)
                minmizedManager.currentStatus = .calling
            } else {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
                ServiceManager.shared.deviceService.enableCamera(userRoomInfo.camera)
                if minmizedManager.viewHiden {
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
                } else {
                    minmizedManager.updateCallStatus(status: .calling, userInfo: currentCallUserInfo, isVideo: true)
                }
            }
        } else {
            ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
            ServiceManager.shared.streamService.startPlaying(userID, streamView: nil)
        }
        ServiceManager.shared.deviceService.enableSpeaker(false)
    }
    
    
    func closeCallVC() {
        minmizedManager.dismissCallMinView()
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
