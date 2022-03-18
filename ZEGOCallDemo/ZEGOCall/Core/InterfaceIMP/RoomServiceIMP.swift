//
//  ZegoRoomService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZegoExpressEngine

class RoomServiceIMP: NSObject {

    // MARK: - Private
    override init() {
        super.init()
        
        // RoomManager didn't finish init at this time.
        DispatchQueue.main.async {
            
        }
    }
    
    // MARK: - Public
    var roomInfo: RoomInfo?
    
  
}

extension RoomServiceIMP: RoomService {

    func joinRoom(_ roomID: String, _ token: String) {
        //TODO: join room
        guard let userID = ServiceManager.shared.userService.localUserInfo?.userID else {
            assert(false, "user id can't be nil.")
            return
        }
        
        // login rtc room
        let user = ZegoUser(userID: userID)
        
        let config = ZegoRoomConfig()
        config.token = token
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config)
    }

    
    func leaveRoom() {
        ZegoExpressEngine.shared().logoutRoom()
    }
}


