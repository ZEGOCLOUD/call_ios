//
//  ZegoRoomService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation

class RoomServiceIMP: NSObject, RoomService {

    // MARK: - Private
    override init() {
        super.init()
        
        // RoomManager didn't finish init at this time.
        DispatchQueue.main.async {
            
        }
    }
    
    // MARK: - Public
    var roomInfo: RoomInfo?
    
    func createRoom(_ roomID: String, _ roomName: String, _ token: String, callback: RoomCallback?) {
        guard roomID.count != 0 else {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        //TODO: create room
        
    }
    
    
    func joinRoom(_ roomID: String, _ token: String, callback: RoomCallback?) {
        //TODO: join room
    }

    
    func leaveRoom(callback: RoomCallback?) {
        // if call the leave room api, just logout rtc room
//        guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID else {
//            assert(false, "room ID can't be nil")
//            guard let callback = callback else { return }
//            callback(.failure(.failed))
//            return
//        }
        
        //TODO: leave room
    }
}


