//
//  CallManagerInterface.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/30.
//

import Foundation

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

protocol CallManagerInterface {
    
    /// The delegate instance of the call manager.
    var delegate: CallManagerDelegate? { get set }
    
    /// The local logged-in user information.
    var localUserInfo: UserInfo? { get }
    
    /// Get CallManager instance
    static var shared: CallManager! { get }
    
    /// Initialize the SDK
    ///
    /// Description: This method can be used to initialize the ZIM SDK and the Express-Audio SDK.
    ///
    /// Call this method at: Before you log in. We recommend you call this method when the application starts.
    ///
    /// - Parameter appID: refers to the project ID. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    func initWithAppID(_ appID: UInt32, callback: ZegoCallback?)
    
    
    func getToken(_ userID: String, callback: RequestCallback?)
    
    /// User to log in
    ///
    /// Description: Call this method with user ID and username to log in to the call service.
    ///
    /// Call this method at: After the SDK initialization
    ///
    /// - Parameter callback: refers to the callback for log in.
    func login(_ token: String, callback: ZegoCallback?) 
    
    /// User to log out
    ///
    /// - Description: This method can be used to log out from the current user account.
    ///
    /// Call this method at: After the user login
    func logout()
    
    func resetCallData()
    
    /// Gets the list of online users
    /// - Parameter callback: <#callback description#>
    func getOnlineUserList(_ callback: UserListCallback?)
    
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
    /// - Parameter userID: refers to the ID of the user you want call.
    /// - Parameter token: refers to the authentication token. To get this, see the documentation: https://docs.zegocloud.com/article/11648
    /// - Parameter type: refers to the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    /// - Parameter callback: refers to the callback for make a outbound call.
    func callUser(_ userInfo: UserInfo, token: String, callType: CallType, callback: ZegoCallback?)
}
