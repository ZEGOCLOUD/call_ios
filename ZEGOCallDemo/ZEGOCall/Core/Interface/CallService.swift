//
//  CallService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation


protocol CallServiceDelegate  {
    /// Callback for receive an incoming call
    ///
    /// Description: This callback will be triggered when receiving an incoming call.
    ///
    /// - Parameter userInfo: refers to the caller information.
    /// - Parameter type: indicates the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    func onReceiveCallInvited(_ userInfo: UserInfo, type: CallType)
    
    /// Callback for receive a canceled call
    ///
    /// Description: This callback will be triggered when the caller cancel the outbound call.
    ///
    /// - Parameter userInfo: refers to the caller information.
    /// - Parameter type: cancel type.
    func onReceiveCallCanceled(_ userInfo: UserInfo, type: CancelType)
    
    func onReceiveCallAccepted(_ userInfo: UserInfo)
    
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType)
    
    /// Callback for end a call
    ///
    /// - Description: This callback will be triggered when the caller or called user ends the call.
    func onReceiveCallEnded()
    
    func onReceiveCallTimeout(_ type: CallTimeoutType)
}

extension CallServiceDelegate {
    func onReceiveCallInvited(_ userInfo: UserInfo , type: CallType) { }
    func onReceiveCallCanceled(_ userInfo: UserInfo, type: CancelType) { }
    func onReceiveCallAccepted(_ userInfo: UserInfo) { }
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType) { }
    func onReceiveCallEnded() { }
    func onReceiveCallTimeout(_ type: CallTimeoutType) { }
}

protocol CallService {
    
    var delegate: CallServiceDelegate? { get set }
    
    var status: LocalUserStatus { get }
    
    var callInfo: CallInfo { get }
    
    /// Make an outbound call
    ///
    /// Description: This method can be used to initiate a call to a online user. The called user receives a notification once this method gets called. And if the call is not answered in 60 seconds, you will need to call a method to cancel the call.
    ///
    /// Call this method at: After the user login
    /// - Parameter userID: refers to the ID of the user you want call.
    /// - Parameter token: refers to the authentication token. To get this, see the documentation: https://docs.zegocloud.com/article/11648
    /// - Parameter type: refers to the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    /// - Parameter callback: refers to the callback for make a outbound call.
    func callUser(_ userID: String, token: String, type: CallType, callback: RoomCallback?)
    
    /// Cancel a call
    ///
    /// Description: This method can be used to cancel a call. And the called user receives a notification through callback that the call has been canceled.
    ///
    /// Call this method at: After the user login
    /// - Parameter userID: refers to the ID of the user you are calling.
    /// - Parameter cancelType: cancel type
    /// - Parameter callback: refers to the callback for cancel a call.
    func cancelCall(userID: String, cancelType: CancelType, callback: RoomCallback?)
    
    func acceptCall(_ token: String, callback: RoomCallback?)
    
    func declineCall(_ userID: String, type: DeclineType, callback: RoomCallback?)
    
    /// End a call
    ///
    /// Description: This method can be used to end a call. After the call is ended, both the caller and called user will be logged out from the room, and the stream publishing and playing stop upon ending.
    ///
    /// Call this method at: After the user login
    /// - Parameter callback refers to the callback for end a call.
    func endCall(_ callback: RoomCallback?)
}
