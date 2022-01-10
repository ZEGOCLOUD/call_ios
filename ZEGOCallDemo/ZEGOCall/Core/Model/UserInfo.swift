//
//  UserInfo.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation

enum UserRole: Codable {
    case participant
    case coHost
    case host
}

class UserInfo: NSObject, Codable {
    /// user ID
    var userID: String?
    
    /// user name
    var userName: String?
    
    /// user role
    var role: UserRole = .participant
    
    // MARK: - local property
    /// user blurred avatar
    var blurredAvatar: String?
    /// has request to co-host
    var hasRequestedCoHost: Bool = false
    /// has add co-hosts
    var hasInvited: Bool = false
    
    override init() {
        
    }
    
    init(_ userID: String, _ userName: String, _ role: UserRole) {
        self.userID = userID
        self.userName = userName
        self.role = role
    }
}
