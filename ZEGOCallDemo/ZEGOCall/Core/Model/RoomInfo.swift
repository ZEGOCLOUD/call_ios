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
        
    enum CodingKeys: String, CodingKey {
        case roomID = "id"
        case roomName = "name"
    }
}

extension RoomInfo: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = RoomInfo()
        copy.roomID = roomID
        copy.roomName = roomName
        return copy
    }
}

