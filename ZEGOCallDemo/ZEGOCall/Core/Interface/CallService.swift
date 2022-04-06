//
//  CallService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation


protocol CallServiceDelegate  {
    /// Callback for received a call
    ///
    /// Description: this callback will be triggered when receives a call invitation.
    ///
    /// - Parameter userInfo: the information of the caller.
    /// - Parameter type: refers to the call type, voice call or video call.
    func onReceiveCallInvited(_ userInfo: UserInfo, type: CallType)
    
    /// Callback for a call canceled
    ///
    /// Description: this callback will be triggered when a call has been cancelled.
    ///
    /// - Parameter userInfo: the information of the caller who canceles the call.
    func onReceiveCallCanceled(_ userInfo: UserInfo)
    
    /// Callback for a call accepted
    ///
    /// Description: this callback will be triggered when a call was accepted.
    ///
    /// - Parameter userInfo: the information of the callee who accepts the call.
    func onReceiveCallAccepted(_ userInfo: UserInfo)
    
    /// The callback for a call declined
    ///
    /// Description: this callback will be triggered when a call was declined.
    ///
    /// - Parameter userInfo: the information of the callee who declines the call.
    /// - Parameter type: the response type of the call.
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType)
    
    /// Callback for a call ended
    ///
    /// - Description: this callback will be triggered when a call has been ended.
    func onReceiveCallEnded()
    
    /// Callback for a call timed out
    ///
    /// - Description: this callback will be triggered when a call didn't get answered for a long time/ the caller or callee timed out during the call.
    func onReceiveCallTimeout(_ type: CallTimeoutType, info: UserInfo)
    
    func onCallingStateUpdated(_ state: CallingState)
}

extension CallServiceDelegate {
    func onReceiveCallInvited(_ userInfo: UserInfo, type: CallType) { }
    func onReceiveCallCanceled(_ userInfo: UserInfo) { }
    func onReceiveCallAccepted(_ userInfo: UserInfo) { }
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType) { }
    func onReceiveCallEnded() { }
    func onReceiveCallTimeout(_ type: CallTimeoutType, info: UserInfo) { }
    func onCallingStateUpdated(_ state: CallingState) { }
}

protocol CallService {
    
    /// callService refers to the delegate instance of call service.
    var delegate: CallServiceDelegate? { get set }
    
    /// The status of a local user.
    var status: LocalUserStatus { get }
    
    /// The call information.
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
    func callUser(_ user: UserInfo, token: String, type: CallType, callback: ZegoCallback?)
    
    /// Cancel a call
    ///
    /// Description: This method can be used to cancel a call. And the called user receives a callback when the call has been canceled.
    ///
    /// Call this method at: after the user login
    /// - Parameter callback: refers to the callback for cancel a call.
    func cancelCall(_ callback: ZegoCallback?)
    
    /// Accept a call
    ///
    /// Description: This method can be used to accept a call. And the caller receives a callback when the call has been accepted by the callee.
    ///
    /// Call this method at: After the user login
    /// - Parameter callback: refers to the callback for accept a call.
    func acceptCall(_ token: String, callback: ZegoCallback?)
    
    /// Decline a call
    ///
    /// Description: This method can be used to decline a call. And the caller receives a callback when the call has been declined by the callee.
    ///
    /// Call this method at: after the user login
    /// - Parameter callback: refers to the callback for decline a call.
    func declineCall(_ callback: ZegoCallback?)
    
    /// End a call
    ///
    /// Description: This method can be used to end a call. And the called user receives a callback when the call has ended.
    ///
    /// Call this method at: after the user login
    /// - Parameter callback: refers to the callback for end a call.  
    func endCall(_ callback: ZegoCallback?)
}
