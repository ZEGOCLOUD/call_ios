//
//  RoomService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation


protocol RoomService {
    
    var roomInfo: RoomInfo? { get }
    
    
    /// Join a room
    ///
    /// Description: This method can be used to join a room, the room must be an existing room.
    ///
    /// Call this method at: After user logs in
    ///
    /// - Parameter roomID: refers to the ID of the room you want to join, and cannot be null.
    /// - Parameter token: refers to the authentication token. To get this, see the documentation: https://doc-en.zego.im/article/11648
    func joinRoom(_ roomID: String, _ token: String)
    
    /// Leave the room
    ///
    /// Description: This method can be used to leave the room you joined. The room will be ended when the Host leaves, and all users in the room will be forced to leave the room.
    ///
    /// Call this method at: After joining a room
    func leaveRoom()
}
