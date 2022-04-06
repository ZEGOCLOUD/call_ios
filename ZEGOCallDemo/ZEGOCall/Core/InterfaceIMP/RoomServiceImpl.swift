//
//  ZegoRoomService.swift
//  ZegoLiveAudioRoomDemo
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
}

extension RoomServiceImpl: RoomService {

    func joinRoom(_ roomID: String, _ token: String) {
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
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config)
        
        // start publish
        let streamID = String.getStreamID(userID, roomID: roomID)
        ZegoExpressEngine.shared().startPublishingStream(streamID)
    }

    
    func leaveRoom() {
        self.roomInfo = nil
        ZegoExpressEngine.shared().stopPublishingStream()
        ZegoExpressEngine.shared().logoutRoom()
    }
}

extension RoomServiceImpl: ZegoEventHandler {
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String) {
        guard let userID = ServiceManager.shared.userService.localUserInfo?.userID else { return }
        ServiceManager.shared.userService.getToken(userID, 24*3600) { result in
            switch result {
            case .success(let token):
                guard let token = token as? String else { return }
                ZegoExpressEngine.shared().renewToken(token, roomID: roomID)
            default:
                break
            }
        }
    }
}


