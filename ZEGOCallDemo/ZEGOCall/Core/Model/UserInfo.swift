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
    
    /// user order
    var order: String?
    
    override init() {
        
    }
    
    init(_ userID: String, _ userName: String) {
        self.userID = userID
        self.userName = userName
    }
    
    init(json: Dictionary<String, Any>) {
        if let userID = json["id"] as? String {
            self.userID = userID
        }
        if let userName = json["name"] as? String {
            self.userName = userName
        }
        if let order = json["order"] as? String {
            self.order = order
        }
    }
}
