//
//  UserInfo.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation

class UserInfo: NSObject, Codable {
    /// User ID, refers to the user unique ID. It can only contains numbers and letters.
    var userID: String?
    
    /// User name, cannot be null.
    var userName: String?
    
    /// The microphone state
    var mic: Bool = true
    
    /// The camera state
    var camera: Bool = true
    
    init(userID: String, userName: String) {
        super.init()
        self.userID = userID
        self.userName = userName
    }
    
    override init() {
        
    }
    
    enum CodingKeys: String, CodingKey {
        case userID = "id"
        case userName = "name"
        case mic = "mic"
        case camera = "camera"
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
    }
}
