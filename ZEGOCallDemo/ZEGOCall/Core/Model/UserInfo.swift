//
//  UserInfo.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation

class UserInfo: NSObject, Codable {
    /// user ID
    var userID: String?
    
    /// user name
    var userName: String?
    
    /// mic
    var mic: Bool = false
    
    /// camera
    var camera: Bool = false
    
    override init() {
        
    }
    
    init(_ userID: String, _ userName: String) {
        self.userID = userID
        self.userName = userName
    }
}
