//
//  ZegoUserService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZIM
import ZegoExpressEngine

enum CallResponseType {
    case accept
    case reject
}

enum CallType {
    case audio
    case video
}

protocol UserServiceDelegate : AnyObject  {
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent)
    /// reveive user info update
    func userInfoUpdate(_ userInfo: UserInfo)
    /// reveive call
    func receiveCall(_ userInfo: UserInfo, type: CallType)
    /// reveive cancel call
    func receiveCancelCall(_ userInfo: UserInfo)
    /// reveive call response
    func receiveCallResponse(_ userInfo: UserInfo, responseType: CallResponseType)
    /// reveive end call
    func receiveEndCall()
}

// default realized
extension UserServiceDelegate {
    func userInfoUpdate(_ userInfo: UserInfo) { }
    func receiveCall(_ userInfo: UserInfo , type: CallType) { }
    func receiveCancelCall(_ userInfo: UserInfo) { }
    func receiveCallResponse(_ userInfo: UserInfo , responseType: CallResponseType) { }
    func receiveEndCall() { }
}

class UserService: NSObject {
    // MARK: - Public
    let delegates = NSHashTable<AnyObject>.weakObjects()
    var localUserInfo: UserInfo?
    var userList = DictionaryArray<String, UserInfo>()
    var roomService: RoomService?
    
    
    override init() {
        super.init()
        
        roomService = RoomService()
        
        // RoomManager didn't finish init at this time.
        DispatchQueue.main.async {
            RoomManager.shared.addZIMEventHandler(self)
        }
    }
    
    func addUserServiceDelegate(_ delegate: UserServiceDelegate) {
        self.delegates.add(delegate)
    }
    
    /// user login with user info and `ZIM token`
    func login(_ user: UserInfo, _ token: String, callback: RoomCallback?) {
        
        guard let userID = user.userID else {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        guard let userName = user.userName else {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        let zimUser = ZIMUserInfo()
        zimUser.userID = userID
        zimUser.userName = userName
        
        ZIMManager.shared.zim?.login(zimUser, token: token, callback: { error in
            var result: ZegoResult
            if error.code == .ZIMErrorCodeSuccess {
                self.localUserInfo = user
                result = .success(())
            } else {
                result = .failure(.other(Int32(error.code.rawValue)))
            }
            guard let callback = callback else { return }
            callback(result)
        })
    }
    
    /// user logout
    func logout() {
        ZIMManager.shared.zim?.logout()
        RoomManager.shared.logoutRtcRoom(true)
    }
    
    func callToUser(_ userID: String, type: CallType) {
        
    }
    
    func cancelCallToUser(userID: String) {
        
    }
    
    func responseCall(_ responseType: CallResponseType) {
        
    }
    
    func endCall() {
        
    }

    
    /// mic operation
    func micOperation(_ open: Bool, callback: RoomCallback?) {
        
//        guard let parameters = getSeatChangeParameters(localUserInfo?.userID, enable: open, flag: 0) else {
//            return
//        }
//
//        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
        // open mic
        ZegoExpressEngine.shared().muteMicrophone(!open)
    }
    
    /// camera operation
    func cameraOpen(_ open: Bool, callback: RoomCallback?) {
        
//        guard let parameters = getSeatChangeParameters(localUserInfo?.userID, enable: open, flag: 1) else {
//            return
//        }
//
//        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
        // open camera
        ZegoExpressEngine.shared().enableCamera(open)
    }
}

// MARK: - Private
extension UserService {
    private func setRoomAttributes(_ attributes: [String : String],
                                   _ roomID: String,
                                   _ config: ZIMRoomAttributesSetConfig, _ callback: RoomCallback?) {
        ZIMManager.shared.zim?.setRoomAttributes(attributes, roomID: roomID, config: config, callback: { error in
            guard let callback = callback else { return }
            if error.code == .ZIMErrorCodeSuccess {
                callback(.success(()))
            } else {
                callback(.failure(.other(Int32(error.code.rawValue))))
            }
        })
    }
}

extension UserService : ZIMEventHandler {
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        for obj  in delegates.allObjects {
            let delegate = obj as? UserServiceDelegate
            guard let delegate = delegate else { continue }
            delegate.connectionStateChanged(state, event)
        }
    }
    

    // recevie a invitation via this method
    func zim(_ zim: ZIM, receivePeerMessage messageList: [ZIMMessage], fromUserID: String) {
        for message in messageList {
            guard let message = message as? ZIMCustomMessage else { continue }
            guard let jsonStr = String(data: message.message, encoding: .utf8) else { continue }
            let command: CustomCommand? = ZegoJsonTool.jsonToModel(type: CustomCommand.self, json: jsonStr)
            guard let command = command else { continue }
            if command.targetUserIDs.count == 0 { continue }
            
            
            for delegate in delegates.allObjects {
                guard let delegate = delegate as? UserServiceDelegate else { continue }
                if command.type == .call {
                    
                } else {
//                    guard let accept = command.content?.accept else { continue }
//                    if let user = self.userList.getObj(command.targetUserIDs.first ?? "") {
//                        delegate.receiveAddCoHostRespond(user, accept: accept)
//                    }
                }
            }
        }
    }
}
