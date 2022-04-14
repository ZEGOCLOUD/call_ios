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
}

// default realized
extension UserServiceDelegate {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel) { }
    func onUserInfoUpdate(_ userInfo: UserInfo) { }
}

protocol UserService {
    
    /// The delegate instance of the user service.
    var delegate: UserServiceDelegate? { get set }
    
    /// The local logged-in user information.
    var localUserInfo: UserInfo? { get }
    
    /// A list of users in the room
    var userList: [UserInfo] { get }
    
    func setLocalUser(_ userID: String, userName: String)
}
