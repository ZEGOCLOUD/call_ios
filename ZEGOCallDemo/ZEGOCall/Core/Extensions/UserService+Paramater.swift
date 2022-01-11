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
    
    // get request or cancel request to host parameters
    func getRequestOrCancelToHostParameters(_ targetUserID: String?, isRequest: Bool) -> ParametersResult? {
//        guard let roomID = RoomManager.shared.roomService.roomInfo.roomID,
//              let myUserID = localUserInfo?.userID,
//              let targetUserID = targetUserID
//        else {
//            assert(false, "the hostID or roomID cannot be nil")
//            return nil
//        }
//
//        let operation = RoomManager.shared.roomService.operation.copy() as! OperationCommand
//        operation.action.seq += 1
//        operation.action.operatorID = myUserID
//        operation.action.targetID = targetUserID
//
//        if isRequest {
//            operation.action.type = .requestToCoHost
//            operation.requestCoHost.append(myUserID)
//        } else {
//            operation.action.type = .cancelRequestCoHost
//            operation.requestCoHost = operation.requestCoHost.filter { $0 != myUserID }
//        }
//
//        let config = ZIMRoomAttributesSetConfig()
//        config.isDeleteAfterOwnerLeft = false
//        config.isForce = true
//        config.isUpdateOwner = true
//
//        let attributes = operation.attributes(.requestCoHost)
//
//        return (attributes, roomID, config)
        return nil
    }
    
    
    func getRespondCoHostParameters(_ agree: Bool, userID: String) -> ParametersResult? {
        
//        guard let roomID = RoomManager.shared.roomService.roomInfo.roomID,
//              let myUserID = localUserInfo?.userID
//        else {
//            assert(false, "the hostID or roomID cannot be nil")
//            return nil
//        }
//
//        let operation = RoomManager.shared.roomService.operation.copy() as! OperationCommand
//        operation.action.seq += 1
//        operation.action.operatorID = myUserID
//        operation.action.targetID = userID
//
//        if !operation.requestCoHost.contains(userID) {
//            assert(false, "the user ID did not in coHost list.")
//            return nil
//        }
//
//        if agree {
//            operation.action.type = .agreeToCoHost
//        } else {
//            operation.action.type = .declineToCoHost
//        }
//        operation.requestCoHost = operation.requestCoHost.filter { $0 != userID }
//
//        let attributes = operation.attributes(.requestCoHost)
//
//        let config = ZIMRoomAttributesSetConfig()
//        config.isDeleteAfterOwnerLeft = false
//        config.isForce = true
//        config.isUpdateOwner = true
//
//        return (attributes, roomID, config)
        
        return nil
    }
}
