//
//  CallManagerInterface.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/30.
//

import Foundation

/// The call status
enum callStatus: Int {
    /// Free
    case free
    /// Receives a call and the call waits to be answered
    case wait
    /// The call waits to be answered by the peer side
    case waitAccept
    /// Connecting
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
    
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String)
    
    func getRTCToken() -> String?
}

// default realized
extension CallManagerDelegate {
    func onReceiveCallInvite(_ userInfo: UserInfo, type: CallType) { }
    func onReceiveCallCanceled(_ userInfo: UserInfo) { }
    func onReceiveCallTimeout(_ type: CallTimeoutType, info: UserInfo) { }
    func onReceivedCallEnded() { }
    func onReceiveCallAccepted(_ userInfo: UserInfo) { }
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType) { }
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String) { }
}

protocol CallManagerInterface {
    
    /// The delegate instance of the call manager.
    var delegate: CallManagerDelegate? { get set }
        
    /// The local logged-in user information.
    var localUserInfo: UserInfo? { get }
        
    /// The state of the current call
    var currentCallStatus: callStatus! { get }
        
    /// Get a CallManager instance
    static var shared: CallManager! { get }
    
    /// Initialize the SDK
    ///
    /// Description: This method can be used to initialize the ZIM SDK and the Express-Audio SDK.
    ///
    /// Call this method at: Before you log in. We recommend you call this method when the application starts.
    ///
    /// - Parameter appID: refers to the project ID. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    func initWithAppID(_ appID: UInt32, callback: ZegoCallback?)
    
    /// The method to deinitialize the SDK
    ///
    /// Description: This method can be used to deinitialize the SDK and release the resources it occupies.
    ///
    /// Call this method at: When the SDK is no longer be used. We recommend you call this method when the application exits.
    func uninit()
        
    /// Set the local user info
    ///
    /// Description: this can be used to save the user information locally.
    ///
    /// Call this method at: after the login
    ///
    /// - Parameter userID: the user ID.
    /// - Parameter userName: the username.
    func setLocalUser(_ userID: String, userName: String)
    
    /// Clear cached data
    ///
    /// - Description: this can be used to clear data cached by the CallManager.
    ///
    /// Call this method at: when logging out from a room or being removed from a room.
    func resetCallData()
        
    /// Upload local logs to the ZEGOCLOUD Server
    ///
    /// Description: You can call this method to upload the local logs to the ZEGOCLOUD Server for troubleshooting when exception occurs.
    ///
    /// Call this method at: When exceptions occur
    ///
    /// - Parameter fileName: refers to the name of the file you upload. We recommend you name the file in the format of "appid_platform_timestamp".
    /// - Parameter callback: refers to the callback that be triggered when the logs are upload successfully or failed to upload logs.
    func uploadLog(_ callback: ZegoCallback?)
    
    /// Make an outbound call
    ///
    /// Description: This method can be used to initiate a call to a online user. The called user receives a notification once this method gets called. And if the call is not answered in 60 seconds, you will need to call a method to cancel the call.
    ///
    /// Call this method at: After the user login
    /// - Parameter userInfo: The information of the user you want to call, including the userID and userName.
    /// - Parameter type: refers to the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    /// - Parameter callback: refers to the callback for make a outbound call.
    func callUser(_ userInfo: UserInfo, callType: CallType, callback: ZegoCallback?)
    
    func renewToken(_ token: String, roomID: String)
}
