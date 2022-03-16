//
//  RoomService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation


protocol RoomService {
    
    var roomInfo: RoomInfo? { get set }
    
    /// Create a room
    ///
    /// Description: This method can be used to create a room. The room creator will be the Host by default when the room is created successfully.
    ///
    /// Call this method at: After user logs in
    ///
    /// - Parameter roomID: refers to the room ID, the unique identifier of the room. This is required to join a room and cannot be null.
    /// - Parameter roomName: refers to the room name. This is used for display in the room and cannot be null.
    /// - Parameter token: refers to the authentication token. To get this, see the documentation: https://doc-en.zego.im/article/11648
    /// - Parameter callback: refers to the callback for create a room.
    func createRoom(_ roomID: String, _ roomName: String, _ token: String, callback: RoomCallback?)
    
    
    /// Join a room
    ///
    /// Description: This method can be used to join a room, the room must be an existing room.
    ///
    /// Call this method at: After user logs in
    ///
    /// - Parameter roomID: refers to the ID of the room you want to join, and cannot be null.
    /// - Parameter token: refers to the authentication token. To get this, see the documentation: https://doc-en.zego.im/article/11648
    /// - Parameter callback: refers to the callback for join a room.
    func joinRoom(_ roomID: String, _ token: String, callback: RoomCallback?)
    
    /// Leave the room
    ///
    /// Description: This method can be used to leave the room you joined. The room will be ended when the Host leaves, and all users in the room will be forced to leave the room.
    ///
    /// Call this method at: After joining a room
    ///
    /// - Parameter callback: refers to the callback for leave a room.
    func leaveRoom(callback: RoomCallback?)
}
