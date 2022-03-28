//
//  UserService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

protocol UserServiceDelegate : AnyObject  {
    
    /// Callback for the network quality
    ///
    /// Description: Callback for the network quality, and this callback will be triggered after the stream publishing or stream playing.     ///
    /// - Parameter userID: Refers to the user ID of the stream publisher or stream subscriber.
    /// - Parameter upstreamQuality: Refers to the stream quality level.
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel)
    
    /// Callback for changes on user state
    ///
    /// Description: This callback will be triggered when the state of the user's microphone/camera changes.
    ///
    /// - Parameter userInfo: refers to the changes on user state information
    func onUserInfoUpdate(_ userInfo: UserInfo)
    
    /// Callback for user is kicked offline
    ///
    /// Description: This callback will be triggered when the user logs in from another device.
    ///
    /// - Parameter UserError: refers to the error type
    func onReceiveUserError(_ error: UserError)
}

// default realized
extension UserServiceDelegate {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel) { }
    func onUserInfoUpdate(_ userInfo: UserInfo) { }
    func onReceiveUserError(_ error: UserError) { }
}

protocol UserService {
    
    var delegate: UserServiceDelegate? { get set }
    
    /// The local logged-in user information.
    var localUserInfo: UserInfo? { get }
    
    /// A list of users in the room
    var userList: [UserInfo] { get }
    
    
    /// User to log in
    ///
    /// Description: Call this method with user ID and username to log in to the LiveAudioRoom service.
    ///
    /// Call this method at: After the SDK initialization
    ///
    /// - Parameter callback: refers to the callback for log in.
    func login(_ token: String, callback: RoomCallback?)
    
    /// User to log out
    ///
    /// - Description: This method can be used to log out from the current user account.
    ///
    /// Call this method at: After the user login
    func logout()
    
    
    /// Gets the list of online users
    /// - Description: This method can be used to gets a list of currently online user members
    /// Call this method at: After the SDK initialization
    func getOnlineUserList(_ callback: UserListCallback?)
}
