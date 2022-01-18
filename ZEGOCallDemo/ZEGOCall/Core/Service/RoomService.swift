//
//  ZegoRoomService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZIM

protocol RoomServiceDelegate: AnyObject {
    func receiveRoomInfoUpdate(_ info: RoomInfo?)
}

class RoomService: NSObject {
    
    // MARK: - Private
    override init() {
        super.init()
        
        // RoomManager didn't finish init at this time.
        DispatchQueue.main.async {
            RoomManager.shared.addZIMEventHandler(self)
        }
    }
    
    // MARK: - Public
    
    var roomInfo: RoomInfo = RoomInfo()
    weak var delegate: RoomServiceDelegate?
    var operation: OperationCommand = OperationCommand()
    /// Create a chat room
    /// You need to enter a generated `rtc token`
    func createRoom(_ roomID: String, _ roomName: String, _ token: String, callback: RoomCallback?) {
        guard roomID.count != 0 else {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        let parameters = getCreateRoomParameters(roomID, roomName)
        ZIMManager.shared.zim?.createRoom(parameters.0, config: parameters.1, callback: { fullRoomInfo, error in
            
            var result: ZegoResult = .success(())
            if error.code == .ZIMErrorCodeSuccess {
                RoomManager.shared.userService.roomService.roomInfo = parameters.2
                RoomManager.shared.loginRtcRoom(with: token)
            }
            else {
                if error.code == .ZIMErrorCodeCreateExistRoom {
                    result = .failure(.roomExisted)
                } else {
                    result = .failure(.other(Int32(error.code.rawValue)))
                }
            }
            
            guard let callback = callback else { return }
            callback(result)
        })
        
    }
    
    /// Join a chat room
    /// You need to enter a generated `rtc token`
    func joinRoom(_ roomID: String, _ token: String, callback: RoomCallback?) {
        ZIMManager.shared.zim?.joinRoom(roomID, callback: { fullRoomInfo, error in
            if error.code != .ZIMErrorCodeSuccess {
                guard let callback = callback else { return }
                if error.code == .ZIMErrorCodeRoomNotExist {
                    callback(.failure(.roomNotFound))
                } else {
                    callback(.failure(.other(Int32(error.code.rawValue))))
                }
                return
            }
            RoomManager.shared.userService.roomService.roomInfo.roomID = fullRoomInfo.baseInfo.roomID
            RoomManager.shared.userService.roomService.getRoomStatus { result in
                guard let callback = callback else { return }
                switch result {
                case .success():
                    RoomManager.shared.loginRtcRoom(with: roomID)
                    callback(.success(()))
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        })
    }
    
    /// Leave the chat room
    func leaveRoom(callback: RoomCallback?) {
        // if call the leave room api, just logout rtc room
        guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID else {
            assert(false, "room ID can't be nil")
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        ZIMManager.shared.zim?.leaveRoom(roomID, callback: { error in
            var result: ZegoResult = .success(())
            if error.code != .ZIMErrorCodeSuccess {
                result = .failure(.other(Int32(error.code.rawValue)))
            }
            RoomManager.shared.logoutRtcRoom()
            

            guard let callback = callback else { return }
            callback(result)
        })
    }
    
    func getRoomStatus(callback: RoomCallback?) {
        guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID else {
            assert(false, "room ID can't be nil")
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        ZIMManager.shared.zim?.queryRoomAllAttributes(byRoomID: roomID, callback: { roomAttributes, error in
            var result: ZegoResult = .success(())
            if error.code == .ZIMErrorCodeSuccess {
                self.roomAttributesUpdated(roomAttributes)
            } else {
                result = .failure(.other(Int32(error.code.rawValue)))
            }
            guard let callback = callback else { return }
            callback(result)
        })
    }
}

// MARK: - Private
extension RoomService {
    
    private func getCreateRoomParameters(_ roomID: String, _ roomName: String) -> (ZIMRoomInfo, ZIMRoomAdvancedConfig, RoomInfo) {
        
        let zimRoomInfo = ZIMRoomInfo()
        zimRoomInfo.roomID = roomID
        zimRoomInfo.roomName = roomName
        
        let roomInfo = RoomInfo()
        roomInfo.hostID = RoomManager.shared.userService.localUserInfo?.userID
        roomInfo.roomID = roomID
        roomInfo.roomName = roomName.count > 0 ? roomName : roomID
        
        let config = ZIMRoomAdvancedConfig()
        let roomInfoJson = ZegoJsonTool.modelToJson(toString: roomInfo) ?? ""
        
        config.roomAttributes = ["room_info" : roomInfoJson]
        
        return (zimRoomInfo, config, roomInfo)
    }
}

extension RoomService: ZIMEventHandler {
    
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        // if host reconneted
        if state == .connected && event == .success {
            guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID else { return }
            ZIMManager.shared.zim?.queryRoomAllAttributes(byRoomID: roomID, callback: { dict, error in
                if error.code != .ZIMErrorCodeSuccess { return }
                if dict.count == 0 {
                    self.delegate?.receiveRoomInfoUpdate(nil)
                }
            })
        }
    }
    
    func zim(_ zim: ZIM, roomAttributesUpdated updateInfo: ZIMRoomAttributesUpdateInfo, roomID: String) {
        roomAttributesUpdated(updateInfo.roomAttributes)
    }
}
