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
    /// Callback for receive an incoming call
    ///
    /// Description: This callback will be triggered when receiving an incoming call.
    ///
    /// - Parameter userInfo: refers to the caller information.
    /// - Parameter type: indicates the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    func onReceiveCallInvite(_ userInfo: UserInfo, type: CallType)
    
    /// Callback for receive a canceled call
    ///
    /// Description: This callback will be triggered when the caller cancel the outbound call.
    ///
    /// - Parameter userInfo: refers to the caller information.
    func onReceiveCallCanceled(_ userInfo: UserInfo)
    
    /// Callback for timeout a call
    ///
    /// - Description: This callback will be triggered when the caller or called user ends the call.
    func onReceiveCallTimeout(_ type: CallTimeoutType, info: UserInfo)
    
    /// Callback for end a call
    ///
    /// - Description: This callback will be triggered when the caller or called user ends the call.
    func onReceivedCallEnded()
    
    /// Callback for call is accept
    ///
    /// - Description: This callback will be triggered when called accept the call.
    func onReceiveCallAccepted(_ userInfo: UserInfo)
    
    /// Callback for call is decline
    ///
    /// - Description: This callback will be triggered when called refused the call.
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType)
    
    /// Callback for user is kickedout
    ///
    /// - Description: This callback will be triggered when user is kickedout.
    func onReceiveUserError(_ error: UserError)
}

// default realized
extension CallManagerDelegate {
    func onReceiveCallInvite(_ userInfo: UserInfo, type: CallType) { }
    func onReceiveCallCanceled(_ userInfo: UserInfo) { }
    func onReceiveCallTimeout(_ type: CallTimeoutType, info: UserInfo) { }
    func onReceivedCallEnded() { }
    func onReceiveCallAccepted(_ userInfo: UserInfo) { }
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType) { }
    func onReceiveUserError(_ error: UserError) { }
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
        ServiceManager.shared.deviceService.delegate = self
        
        callKitService = AppleCallKitServiceIMP()
    }
    
    
    /// Initialize the SDK
    ///
    /// Description: This method can be used to initialize the ZIM SDK and the Express-Audio SDK.
    ///
    /// Call this method at: Before you log in. We recommend you call this method when the application starts.
    ///
    /// - Parameter appID: refers to the project ID. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    public func initWithAppID(_ appID: UInt32, callback: RoomCallback?) {
        ServiceManager.shared.initWithAppID(appID: appID, callback: callback)
    }
    
    /// User to log in
    ///
    /// Description: Call this method with user ID and username to log in to the call service.
    ///
    /// Call this method at: After the SDK initialization
    ///
    /// - Parameter callback: refers to the callback for log in.
    public func login(_ token: String, callback: RoomCallback?) {
        ServiceManager.shared.userService.login(token, callback: callback)
    }
    
    /// User to log out
    ///
    /// - Description: This method can be used to log out from the current user account.
    ///
    /// Call this method at: After the user login
    public func logout() {
        resetCallData()
        ServiceManager.shared.userService.logout()
    }
    
    
    public func resetCallData() {
        minmizedManager.dismissCallMinView()
        switch currentCallStatus {
        case .free:
            break
        case .wait:
            CallAcceptTipView.dismiss()
            currentCallStatus = .free
            currentCallUserInfo = nil
            audioPlayer?.stop()
            endSystemCall()
        case .waitAccept:
            guard let userID = currentCallUserInfo?.userID else { return }
            guard let currentCallVC = currentCallVC else { return }
            cancelCall(userID, callType: currentCallVC.vcType)
        case .calling:
            guard let userID = currentCallUserInfo?.userID else { return }
            endCall(userID)
        }
    }
    
    
    /// Gets the list of online users
    /// - Parameter callback: <#callback description#>
    public func getOnlineUserList(_ callback: UserListCallback?)  {
        ServiceManager.shared.userService.getOnlineUserList(callback)
    }
    
    /// Upload local logs to the ZEGOCLOUD Server
    ///
    /// Description: You can call this method to upload the local logs to the ZEGOCLOUD Server for troubleshooting when exception occurs.
    ///
    /// Call this method at: When exceptions occur
    ///
    /// - Parameter fileName: refers to the name of the file you upload. We recommend you name the file in the format of "appid_platform_timestamp".
    /// - Parameter callback: refers to the callback that be triggered when the logs are upload successfully or failed to upload logs.
    public func uploadLog(_ callback: RoomCallback?) {
        ServiceManager.shared.uploadLog(callback: callback)
    }
    
    
    public func enableAppleCallKit(_ enable: Bool) {
        enableCallKit = enable
    }
    
    /// Make an outbound call
    ///
    /// Description: This method can be used to initiate a call to a online user. The called user receives a notification once this method gets called. And if the call is not answered in 60 seconds, you will need to call a method to cancel the call.
    ///
    /// Call this method at: After the user login
    /// - Parameter userID: refers to the ID of the user you want call.
    /// - Parameter token: refers to the authentication token. To get this, see the documentation: https://docs.zegocloud.com/article/11648
    /// - Parameter type: refers to the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    /// - Parameter callback: refers to the callback for make a outbound call.
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
        ServiceManager.shared.callService.acceptCall(rtcToken) { result in
            switch result {
            case .success():
                self.audioPlayer?.stop()
                let callVC: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .calling)
                callVC.otherUserRoomInfo = self.otherUserRoomInfo
                self.currentCallVC = callVC
                self.currentCallStatus = .calling
                self.currentCallUserInfo = userInfo
                self.callTimeManager.callStart()
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
    
    func declineCall(_ userID: String, type: DeclineType) {
        if currentCallUserInfo?.userID == userID {
            currentCallStatus = .free
            currentCallUserInfo = nil
            otherUserRoomInfo = nil
        }
        ServiceManager.shared.callService.declineCall(userID, type: type, callback: nil)
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
            declineCall(userID, type: .decline)
        }
    }
    
    func cancelCall(_ userID: String, callType: CallType, isTimeout: Bool = false) {
        ServiceManager.shared.callService.cancelCall(userID: userID) { result in
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
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
                ServiceManager.shared.streamService.startPlaying(userID, streamView: nil)
            } else {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
                ServiceManager.shared.deviceService.enableCamera(userRoomInfo.camera)
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
            ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
            ServiceManager.shared.streamService.startPlaying(userID, streamView: nil)
        }
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
