//
//  ZegoRoomService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZegoExpressEngine

class RoomServiceImpl: NSObject {

    // MARK: - Private
    override init() {
        super.init()
        
        // RoomManager didn't finish init at this time.
        DispatchQueue.main.async {
            ServiceManager.shared.addExpressEventHandler(self)
        }
    }
    
    // MARK: - Public
    var roomInfo: RoomInfo?
    
    var delegate: RoomServiceDelegate?
}

extension RoomServiceImpl: RoomService {

    func joinRoom(_ roomID: String, _ token: String) {
        
        assert(ServiceManager.shared.isSDKInit, "The SDK must be initialised first.")
        assert(ServiceManager.shared.userService.localUserInfo != nil, "Must be logged in first.")
        
        guard let userID = ServiceManager.shared.userService.localUserInfo?.userID else {
            assert(false, "user ID can't be nil.")
            return
        }
        roomInfo = RoomInfo()
        roomInfo?.roomID = roomID
        
        let userName = ServiceManager.shared.userService.localUserInfo?.userName ?? ""
        // login rtc room
        let user = ZegoUser(userID: userID, userName: userName)
        
        let config = ZegoRoomConfig()
        config.isUserStatusNotify = true
        config.token = token
        print("[* Join Room] current userID: \(userID), token: \(token)")
        
        ZegoExpressEngine.shared().logoutRoom()
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config)
        
        // start publish
        let streamID = String.getStreamID(userID, roomID: roomID)
        ZegoExpressEngine.shared().startPublishingStream(streamID)
    }

    
    func leaveRoom() {
        assert(ServiceManager.shared.isSDKInit, "The SDK must be initialised first.")
        assert(ServiceManager.shared.userService.localUserInfo != nil, "Must be logged in first.")
        
        self.roomInfo = nil
        ZegoExpressEngine.shared().stopPublishingStream()
        ZegoExpressEngine.shared().logoutRoom()
    }
    
    func renewToken(_ token: String, roomID: String) {
        ZegoExpressEngine.shared().renewToken(token, roomID: roomID)
    }
}

extension RoomServiceImpl: ZegoEventHandler {
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String) {
        delegate?.onRoomTokenWillExpire(remainTimeInSecond, roomID: roomID)
    }
}


