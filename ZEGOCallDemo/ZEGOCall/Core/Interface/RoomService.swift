//
//  RoomService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

protocol RoomServiceDelegate {
    /// Callback notification that room Token authentication is about to expire.
    ///
    /// Description: The callback notification that the room Token authentication is about to expire, please use [renewToken] to update the room Token authentication.
    ///
    /// @param remainTimeInSecond The remaining time before the token expires.
    /// @param roomID Room ID where the user is logged in, a string of up to 128 bytes in length.
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String)
}


protocol RoomService {
    
    var roomInfo: RoomInfo? { get }
    
    var delegate: RoomServiceDelegate? { get set }
    
    /// Join a room
    ///
    /// Description: This method can be used to join a room, and the room must be an existing room.
    ///
    /// Call this method at: after user logs in
    ///
    /// - Parameter roomID: refers to the ID of the room you want to join, and this cannot be null.
    /// - Parameter token: refers to the Token for authentication. To get this, refer to the documentation: https://doc-en.zego.im/article/11648
    func joinRoom(_ roomID: String, _ token: String)
    
    /// Leave a room
    ///
    /// Description: This method can be used to leave the room you joined. The room will be ended when the Host left the room, and all users in the room will be forced to leave the room.
    ///
    /// Call this method at: after joining a room
    func leaveRoom()
    
    /// Renew token.
    ///
    /// Description: After the developer receives [onRoomTokenWillExpire], they can use this API to update the token to ensure that the subsequent RTC functions are normal.
    ///
    /// @param token The token that needs to be renew.
    /// @param roomID Room ID.
    func renewToken(_ token: String, roomID: String)
}
