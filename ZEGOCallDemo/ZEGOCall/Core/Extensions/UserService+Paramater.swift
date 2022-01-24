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
        
        guard let userInfo = localUserRoomInfo else {
            return nil
        }
        
        guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID,
              let myUserID = userInfo.userID,
              let myUserName = userInfo.userName
        else {
            assert(false, "roomID cannot be nil")
            return nil
        }
        
        var attributes: [String: String] = [:]
        if let userJson = ZegoJsonTool.modelToJson(toString: userInfo) {
            attributes[myUserID] = userJson
        }
        
        let config = ZIMRoomAttributesSetConfig()
        config.isDeleteAfterOwnerLeft = false
        config.isForce = true
        config.isUpdateOwner = true
        return (attributes, roomID, config)
    }
}
