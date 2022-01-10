//
//  RoomService+Private.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/27.
//

import Foundation
import ZIM
import ZegoExpressEngine

extension RoomService {
    
    func roomAttributesUpdated(_ roomAttributes: [String: String]) {
        // update room info
        if roomAttributes.keys.contains("room_info") {
            let roomJson = roomAttributes["room_info"] ?? ""
            let roomInfo = ZegoJsonTool.jsonToModel(type: RoomInfo.self, json: roomJson)
            
            // if the room info is nil, we should not set self.info = nil
            // because it can't get room info outside.
            if let roomInfo = roomInfo {
                self.roomInfo = roomInfo
            }
            delegate?.receiveRoomInfoUpdate(roomInfo)
        }
        
        // update action
        guard let actionJson = roomAttributes["action"],
              let action: OperationAction = ZegoJsonTool.jsonToModel(type: OperationAction.self, json: actionJson)
        else {
            return
        }
        roomAttributesUpdated(roomAttributes, action: action)
    }
    
    private func roomAttributesUpdated(_ roomAttributes: [String: String], action: OperationAction) {
        // if the seq is invalid
        if !operation.isSeqValid(action.seq) {
            resendRoomAttributes(roomAttributes, action: action)
            return
        } else {
            self.operation.action = action
        }
        
        // update seat list
        if let seatJson = roomAttributes["co_host"] {
            self.operation.updateSeatList(seatJson)
        }
        
        // update coHost list
        if let coHostJson = roomAttributes["request_co_host"] {
            operation.updateRequestCoHostList(coHostJson)
            for user in RoomManager.shared.userService.userList.allObjects() {
                guard let userID = user.userID else { continue }
                if operation.requestCoHost.contains(userID) {
                    user.hasRequestedCoHost = true
                } else {
                    user.hasRequestedCoHost = false
                }
            }
        }
        
        // update the user role
        let coHostUserIDs = self.operation.coHost.compactMap { $0.userID }
        for user in RoomManager.shared.userService.userList.allObjects() {
            if user.role == .host { continue }
            guard let userID = user.userID else {
                user.role = .participant
                continue
            }
            if coHostUserIDs.contains(userID) {
                user.role = .coHost
            } else {
                user.role = .participant
            }
        }
        
        // delegate to UI
        let myUserID = RoomManager.shared.userService.localUserInfo?.userID ?? ""
        let isMyselfUpdate = myUserID == action.targetID
        let isMyselfHost = RoomManager.shared.userService.isMyselfHost
        let isOperatedSelf = action.targetID == action.operatorID
        let targetUser = RoomManager.shared.userService.userList.getObj(action.targetID) ?? UserInfo()
       
        for delegate in RoomManager.shared.userService.delegates.allObjects {
            guard let delegate = delegate as? UserServiceDelegate else { continue }
            
            switch action.type {
            case .requestToCoHost:
                if isMyselfHost {
                    delegate.receiveToCoHostRequest(targetUser)
                }
            case .cancelRequestCoHost:
                if isMyselfHost {
                    delegate.receiveCancelToCoHostRequest(targetUser)
                }
            case .agreeToCoHost:
                if isMyselfUpdate {
                    delegate.receiveToCoHostRespond(true)
                }
            case .declineToCoHost:
                if isMyselfUpdate {
                    delegate.receiveToCoHostRespond(false)
                }
            case .takeCoHostSeat:
                delegate.coHostChange(action.targetID, type: .add)
            case .leaveCoHostSeat:
                // coHost leave or host remove coHost
                if isOperatedSelf {
                    delegate.coHostChange(action.targetID, type: .leave)
                } else {
                    delegate.coHostChange(action.targetID, type: .remove)
                }
            case .mic:
                delegate.coHostChange(action.targetID, type: .mic)
            case .camera:
                delegate.coHostChange(action.targetID, type: .camera)
            case .mute:
                delegate.coHostChange(action.targetID, type: .mute)
            default: break
            }
        }
        
        // if it is myself update
        if !isMyselfUpdate { return }
        
        // myself leave the coHost seat(leave or be removed)
        if action.type == .leaveCoHostSeat {
            ZegoExpressEngine.shared().stopPublishingStream()
        }
        
        let seat = self.operation.coHost.filter({ $0.userID == action.targetID }).first
        guard let seat = seat else { return }
        
        if action.type == .mic {
            ZegoExpressEngine.shared().muteMicrophone(!seat.mic)
        }
        if action.type == .camera {
            ZegoExpressEngine.shared().enableCamera(seat.camera)
        }
        
        if action.type == .mute && seat.isMuted {
            ZegoExpressEngine.shared().muteMicrophone(true)
            RoomManager.shared.userService.micOperation(false)
        }
    }
    
    private func resendRoomAttributes(_ roomAttributes: [String: String], action: OperationAction) {
        
        // only the host can resend the room attributes
        if !RoomManager.shared.userService.isMyselfHost { return }
        
        guard let roomID = RoomManager.shared.roomService.roomInfo.roomID else { return }
        
        let operation = OperationCommand()
        operation.action = action
        operation.action.seq += 1
        
        var attributeType: OperationAttributeType = []
        // update seat list from json
        if let seatJson = roomAttributes["co_host"] {
            operation.updateSeatList(seatJson)
            attributeType.insert(.coHost)
        }
        
        // update coHost list from json
        if let coHostJson = roomAttributes["request_co_host"] {
            operation.updateRequestCoHostList(coHostJson)
            attributeType.insert(.coHost)
        }
        
        // update the operator's seat info to local seat list
        if action.type == .mic ||
            action.type == .camera ||
            action.type == .mute {
            
            let seat = operation.coHost.filter { $0.userID == action.targetID }.first
            operation.coHost = self.operation.coHost
            let newSeat = operation.coHost.filter { $0.userID == action.targetID }.first
            if let seat = seat, let newSeat = newSeat {
                newSeat.updateModel(seat)
            }
        }
        
        // update the seat list
        if action.type == .takeCoHostSeat {
            let seat = operation.coHost.filter { $0.userID == action.targetID }.first
            operation.coHost = self.operation.coHost.filter { $0.userID != action.targetID }
            if let seat = seat { operation.coHost.append(seat) }
        }
        if action.type == .leaveCoHostSeat {
            operation.coHost = self.operation.coHost.filter { $0.userID != action.targetID }
        }
        
        // update the co-host list
        if action.type == .requestToCoHost {
            operation.requestCoHost = self.operation.requestCoHost.filter { $0 != action.targetID }
            operation.requestCoHost.append(action.targetID)
        }
        if action.type == .cancelRequestCoHost ||
            action.type == .declineToCoHost ||
            action.type == .agreeToCoHost {
            operation.requestCoHost = self.operation.requestCoHost.filter { $0 != action.targetID }
        }
        
        let newRoomAttributes = operation.attributes(attributeType)
        
        let config = ZIMRoomAttributesSetConfig()
        config.isDeleteAfterOwnerLeft = false
        config.isForce = true
        config.isUpdateOwner = true
        ZIMManager.shared.zim?.setRoomAttributes(newRoomAttributes, roomID: roomID, config: config, callback: { error in
            
        })
    }
    
}
