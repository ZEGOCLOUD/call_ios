//
//  UserService+Paramater.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/25.
//

import Foundation
import ZIM

// MARK: - Private
extension UserService {
    
    typealias ParametersResult = ([String: String], String, ZIMRoomAttributesSetConfig)
    
    func getDeviceChangeParameters(_ enable: Bool, flag: Int) -> ParametersResult? {
        
        guard let userInfo = localUserInfo else {
            return nil
        }
        
        guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID,
              let myUserID = localUserInfo?.userID,
              let myUserName = localUserInfo?.userName
        else {
            assert(false, "roomID cannot be nil")
            return nil
        }
        
        let attributes:[String : String] = ["id": myUserID, "name": myUserName, "mic": userInfo.mic.description, "camera": userInfo.camera.description]
        
        let config = ZIMRoomAttributesSetConfig()
        config.isDeleteAfterOwnerLeft = false
        config.isForce = true
        config.isUpdateOwner = true
        return (attributes, roomID, config)
    }
}
