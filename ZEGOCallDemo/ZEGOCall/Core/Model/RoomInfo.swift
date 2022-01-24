//
//  RoomInfo.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation

class RoomInfo: NSObject, Codable {
    /// room ID
    var roomID: String?
    
    /// room name
    var roomName: String?
    
    /// host user ID
    var hostID: String?
    
    /// host user ID
    var userNum: Int?
    
    enum CodingKeys: String, CodingKey {
        case roomID = "id"
        case roomName = "name"
        case hostID = "host_id"
        case userNum = "user_num"
    }
}

extension RoomInfo: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = RoomInfo()
        copy.roomID = roomID
        copy.roomName = roomName
        copy.hostID = hostID
        copy.userNum = userNum
        return copy
    }
}

