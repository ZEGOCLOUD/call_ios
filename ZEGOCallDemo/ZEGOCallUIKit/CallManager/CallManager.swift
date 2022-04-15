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
    var localUserInfo: UserInfo? {
        get {
            ServiceManager.shared.userService.localUserInfo
        }
    }
    /// Current call page
    var currentCallVC: CallMainVC?
    /// Current call user info
    var currentCallUserInfo: UserInfo?
    /// Call type
    var callKitCallType: CallType = .voice
    /// App current state
    var appIsActive: Bool = true
    /// current call notification message view
    var currentTipView: CallAcceptTipView?
    /// call kit service
    var callKitService: AppleCallKitServiceIMP?
    /// uuid used as call identify
    var myUUID: UUID = UUID()
    /// current call connecting state
    var isConnecting: Bool = false
    
    /// audio player tool
    lazy var audioTool: AudioPlayerTool = {
        let audioPlayTool = AudioPlayerTool()
        return audioPlayTool
    }()
    
    /// call time manager
    lazy var callTimeManager: CallTimeManager = {
        let manager = CallTimeManager()
        manager.delegate = self
        return manager
    }()
    
    /// minimization management
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
        ServiceManager.shared.roomService.delegate = self
        
        callKitService = AppleCallKitServiceIMP()
        callKitService?.providerDelegate = ProviderDelegate()
    }
    
    // MARK: -Public
    func initWithAppID(_ appID: UInt32, callback: ZegoCallback?) {
        ServiceManager.shared.initWithAppID(appID: appID, callback: callback)
    }
    
    func uninit() {
        ServiceManager.shared.uninit()
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
            audioTool.stopPlay()
            endSystemCall()
            closeCallVC()
        case .waitAccept:
            cancelCall()
        case .calling:
            endCall()
            closeCallVC()
        case .none:
            break
        }
    }
        
    public func uploadLog(_ callback: ZegoCallback?) {
        ServiceManager.shared.uploadLog(callback: callback)
    }
    
    func renewToken(_ token: String, roomID: String) {
        ServiceManager.shared.roomService.renewToken(token, roomID: roomID)
    }
    
    func callUser(_ userInfo: UserInfo, callType: CallType, callback: ZegoCallback?) {
        if currentCallStatus != .free { return }
        self.currentCallStatus = .waitAccept
        resetDeviceConfig()
        let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .take)
        currentCallVC = vc
        currentCallUserInfo = userInfo
        getCurrentViewController()?.present(vc, animated: true, completion: nil)
        ServiceManager.shared.deviceService.useFrontCamera(true)
        
        delegate?.getRTCToken({ token in
            if self.currentCallStatus != .waitAccept {
                return
            }
            guard let token = token else {
                self.currentCallStatus = .free
                self.currentCallVC?.changeCallStatusText(.canceled)
                vc.callDelayDismiss()
                return
            }
            ServiceManager.shared.callService.callUser(userInfo, token: token, type: callType) { result in
                switch result {
                case .success():
                    guard let callback = callback else { return }
                    callback(result)
                case .failure(_):
                    self.currentCallStatus = .free
                    guard let callback = callback else { return }
                    callback(result)
                }
            }
        })
    }
    
    //MARK: -Privare
    
    /// Answering the call
    /// - Parameters:
    ///   - userInfo: The other user info
    ///   - callType: call type
    ///   - presentVC: Whether present the Call page: default true
    func acceptCall(_ userInfo: UserInfo, callType: CallType, presentVC:Bool = true) {
        audioTool.stopPlay()
        guard let userID = userInfo.userID else {
            currentCallStatus = .free
            return
        }
        resetDeviceConfig()
        ServiceManager.shared.deviceService.useFrontCamera(true)
        if presentVC {
            let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .accepting)
            callVC.otherUser = self.currentCallUserInfo
            self.currentCallVC = callVC
            if let controller = self.getCurrentViewController() {
                controller.present(callVC, animated: true, completion: nil)
            }
        } else {
            guard let currentCallVC = self.currentCallVC else { return }
            currentCallVC.otherUser = self.currentCallUserInfo
            currentCallVC.updateCallType(callType, userInfo: userInfo, status: .accepting)
        }
        
        delegate?.getRTCToken({ token in
            guard let token = token else {
                self.currentCallStatus = .free
                self.currentCallVC?.changeCallStatusText(.decline)
                self.currentCallVC?.callDelayDismiss()
                return
            }
            ServiceManager.shared.callService.acceptCall(token) { result in
                switch result {
                case .success():
                    self.currentCallStatus = .calling
                    self.currentCallUserInfo = userInfo
                    self.callTimeManager.callStart()
                    self.minmizedManager.currentStatus = .calling
                    self.startPlayingStream(userID)
                    self.currentCallVC?.updateCallType(callType, userInfo: userInfo, status: .calling)
                case .failure(_):
                    self.currentCallStatus = .free
                    self.currentCallVC?.changeCallStatusText(.decline)
                    self.currentCallVC?.callDelayDismiss()
                }
            }
        })
    }
    
    /// decline call
    func declineCall() {
        currentCallStatus = .free
        currentCallUserInfo = nil
        audioTool.stopPlay()
        ServiceManager.shared.callService.declineCall(nil)
    }
    
    /// end call
    func endCall() {
        if ServiceManager.shared.callService.status == .calling {
            minmizedManager.updateCallStatus(status: .end, userInfo: currentCallUserInfo)
            ServiceManager.shared.callService.endCall(nil)
        } else {
            minmizedManager.updateCallStatus(status: .decline, userInfo: currentCallUserInfo)
            declineCall()
        }
        minmizedManager.dismissCallMinView()
        currentCallStatus = .free
        currentCallUserInfo = nil
        endSystemCall()
    }
    
    /// cancel call
    func cancelCall() {
        audioTool.stopPlay()
        currentCallStatus = .free
        currentCallVC?.changeCallStatusText(.canceled)
        currentCallVC?.callDelayDismiss()
        minmizedManager.dismissCallMinView()
        ServiceManager.shared.callService.cancelCall(nil)
    }
    
    /// reset device config
    func resetDeviceConfig() {
        ServiceManager.shared.userService.localUserInfo?.mic = true
        ServiceManager.shared.userService.localUserInfo?.camera = true
        ServiceManager.shared.deviceService.resetDeviceConfig()
    }
    
    /// start playing stream
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
                    ServiceManager.shared.streamService.startPreview(vc.localPreviewView)
                    ServiceManager.shared.streamService.startPlaying(userID, streamView: vc.remotePreviewView)
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
    
    /// close call page
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
