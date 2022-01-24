//
//  UserRoomInfo.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/23.
//

import UIKit

class UserRoomInfo: NSObject, Codable {
    /// user ID
    var userID: String?
    
    /// user name
    var userName: String?
    
    /// mic
    var mic: Bool = true
    
    /// camera
    var camera: Bool = true
    
    /// voice
    var voice: Bool?
    
    override init() {
        
    }
    
    enum CodingKeys: String, CodingKey {
        case userID = "id"
        case userName = "name"
        case mic = "mic"
        case camera = "camera"
    }
    
    init(_ userID: String, _ userName: String, _ mic: Bool = true, _ camera: Bool = true) {
        self.userID = userID
        self.userName = userName
        self.mic = mic
        self.camera = camera
    }
    
    init(json: Dictionary<String, Any>) {
        if let userID = json["id"] as? String {
            self.userID = userID
        }
        if let userName = json["name"] as? String {
            self.userName = userName
        }
        if let mic = json["mic"] as? Bool {
            self.mic = mic
        }
        if let camera = json["camera"] as? Bool {
            self.camera = camera
        }
    }
}
