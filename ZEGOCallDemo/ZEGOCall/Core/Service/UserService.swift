//
//  ZegoUserService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZIM
import ZegoExpressEngine
import AVFoundation

enum CallResponseType: Int {
    case accept = 1
    case reject = 2
}

enum CancelType: Int {
    case intent = 1
    case timeout = 2
}

enum CallType: Int {
    case audio = 1
    case video = 2
}

protocol UserServiceDelegate : AnyObject  {
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent)
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel)
    /// reveive user info update
    func userInfoUpdate(_ userInfo: UserInfo)
    /// reveive call
    func receiveCall(_ userInfo: UserInfo, type: CallType)
    /// reveive cancel call
    func receiveCancelCall(_ userInfo: UserInfo, type: CancelType)
    /// reveive call response
    func receiveCallResponse(_ userInfo: UserInfo, responseType: CallResponseType)
    /// reveive end call
    func receiveEndCall()
}

// default realized
extension UserServiceDelegate {
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent){ }
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel) { }
    func userInfoUpdate(_ userInfo: UserInfo) { }
    func receiveCall(_ userInfo: UserInfo , type: CallType) { }
    func receiveCancelCall(_ userInfo: UserInfo, type: CancelType) { }
    func receiveCallResponse(_ userInfo: UserInfo , responseType: CallResponseType) { }
    func receiveEndCall() { }
}

class UserService: NSObject {
    
    // MARK: - Public
    var delegates = NSHashTable<AnyObject>.weakObjects()
    var localUserInfo: UserInfo?
    var localUserRoomInfo: UserInfo?
    var userList = DictionaryArray<String, UserInfo>()
    var roomService: RoomService = RoomService()
    var deviceService: DeviceService = DeviceService()
    let timer = ZegoTimer(15000)
    
    
    override init() {
        super.init()
        // RoomManager didn't finish init at this time.
        DispatchQueue.main.async {
            RoomManager.shared.addZIMEventHandler(self)
        }
        roomService.delegate = self
    }
    
    func addUserServiceDelegate(_ delegate: UserServiceDelegate) {
        self.delegates.add(delegate)
    }
    
    func requestUserID(_ callback: UserIDCallBack?) {
        let request = UserIDReauest()
        RequestManager.shared.getUserIDRequest(request: request) { requestStatus in
            guard let callback = callback else { return }
            let userID: String = requestStatus?.data["id"] as? String ?? ""
            callback(.success(userID))
        } failure: { requestStatus in
            guard let callback = callback else { return }
            callback(.failure(.failed))
        }

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
        
        var request = LoginRequest()
        request.userID = userID
        request.name = userName
        RequestManager.shared.loginRequest(request: request) { requestStatus in
            
            user.order = requestStatus?.data["order"] as? String ?? ""
            
            self.timer.setEventHandler {
                self.heartBeatRequest()
            }
            self.timer.start()
            
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
            
            
        } failure: { requestStatus in
            guard let callback = callback else { return }
            let result: ZegoResult = .failure(.other(Int32(requestStatus?.code ?? 0)))
            callback(result)
        }
    }
    
    /// user logout
    func logout() {
        ZIMManager.shared.zim?.logout()
        RoomManager.shared.logoutRtcRoom(true)
    }
    
    func callToUser(_ userID: String, token:String, type: CallType, callback: RoomCallback?) {
        guard let myUserID = localUserInfo?.userID else { return }
        guard let myUserName = localUserInfo?.userName else { return }
        roomService.createRoom(myUserID, myUserName, token) { [self] result in
            localUserRoomInfo = UserInfo(myUserID,myUserName)
            localUserRoomInfo?.voice = true
            switch result {
            case .success():
                sendPeerMesssage(userID, callType: type, cancelType: nil, commandType: .call, responseType: nil) { result in
                    switch result {
                    case .success():
                        guard let callback = callback else { return }
                        callback(result)
                    case .failure(let error):
                        self.roomService.leaveRoom(callback: nil)
                        guard let callback = callback else { return }
                        let result: ZegoResult = .failure(.other(Int32(error.code)))
                        callback(result)
                    }
                }
            case .failure(let error):
                guard let callback = callback else { return }
                let result: ZegoResult = .failure(.other(Int32(error.code)))
                callback(result)
            }
        }
    }
    
    func cancelCallToUser(userID: String, responeType: CancelType, callback: RoomCallback?) {
        sendPeerMesssage(userID, callType: nil, cancelType: responeType, commandType: .cancel, responseType: .none) { result in
            switch result {
            case .success():
                self.roomService.leaveRoom { result in
                    guard let callback = callback else { return }
                    callback(result)
                }
            case .failure(let error):
                guard let callback = callback else { return }
                let result: ZegoResult = .failure(.other(Int32(error.code)))
                callback(result)
            }
        }
    }
    
    func responseCall(_ userID: String, token:String, responseType: CallResponseType, callback: RoomCallback?) {
        if responseType == .accept {
            self.roomService.joinRoom(userID, token) { result in
                switch result {
                case .success():
                    ///start publish
                    guard let myUserID = self.localUserInfo?.userID else { return }
                    self.localUserRoomInfo = UserInfo(myUserID,self.localUserInfo?.userName ?? "")
                    let streamID = String.getStreamID(myUserID, roomID: userID)
                    ZegoExpressEngine.shared().startPublishingStream(streamID)
                    ///send peer message
                    self.sendPeerMesssage(userID, callType: nil, cancelType: nil, commandType: .reply, responseType: responseType, callback: callback)
                case .failure(let error):
                    guard let callback = callback else { return }
                    let result: ZegoResult = .failure(.other(Int32(error.code)))
                    callback(result)
                }
            }
        } else {
            sendPeerMesssage(userID, callType: nil, cancelType: nil, commandType: .reply, responseType: .reject, callback: callback)
        }
    }
    
    
    func endCall(callback: RoomCallback?) {
        self.roomService.leaveRoom { result in
            switch result {
            case .success():
                ZegoExpressEngine.shared().stopPublishingStream()
                guard let callback = callback else { return }
                callback(.success(()))
            case .failure(let error):
                guard let callback = callback else { return }
                let result: ZegoResult = .failure(.other(Int32(error.code)))
                callback(result)
            }
        }
    }
    
    private func sendPeerMesssage(_ userID: String, callType: CallType?, cancelType: CancelType?, commandType: CustomCommandType, responseType: CallResponseType?, callback: RoomCallback?) {
        
        let invitation = CustomCommand(commandType)
        invitation.targetUserIDs.append(userID)
        
        var content: CustomCommandContent = CustomCommandContent()
        switch commandType {
        case .call:
            guard let callType = callType else { return }
            content = CustomCommandContent(user_info: ["id": localUserInfo?.userID ?? "", "name" : localUserInfo?.userName ?? ""], call_type: callType.rawValue)
        case .reply:
            content = CustomCommandContent(user_info: ["id": localUserInfo?.userID ?? "", "name" : localUserInfo?.userName ?? ""], response_type: responseType?.rawValue ?? 1)
        case .cancel:
            content = CustomCommandContent(user_info: ["id": localUserInfo?.userID ?? "", "name" : localUserInfo?.userName ?? ""],cancel_type: cancelType?.rawValue ?? 1)
        case .end:
            content = CustomCommandContent(user_info: ["id": localUserInfo?.userID ?? "", "name" : localUserInfo?.userName ?? ""])
        }
        invitation.content = content
        
        guard let json = invitation.json(),
              let data = json.data(using: .utf8) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        let customMessage: ZIMCustomMessage = ZIMCustomMessage(message: data)
        ZIMManager.shared.zim?.sendPeerMessage(customMessage, toUserID: userID, callback: { _, error in
            var result: ZegoResult
            if error.code == .ZIMErrorCodeSuccess {
                result = .success(())
            } else {
                result = .failure(.other(Int32(error.code.rawValue)))
            }
            guard let callback = callback else { return }
            callback(result)
        })
    }

    
    /// mic operation
    func micOperation(_ open: Bool, callback: RoomCallback?) {
        
        guard let parameters = getDeviceChangeParameters(open, flag: 0) else {
            return
        }

        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
        // open mic
        deviceService.muteMicrophone(!open)
    }
    
    /// camera operation
    func cameraOpen(_ open: Bool, callback: RoomCallback?) {
        
        guard let parameters = getDeviceChangeParameters(open, flag: 1) else {
            return
        }

        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
        // open camera
        deviceService.enableCamera(open)
    }
    
    func enableSpeaker(_ enable: Bool) {
        /// open voice
        deviceService.enableSpeaker(enable)
    }
    
    func useFrontCamera(_ enable: Bool) {
        /// use front camera
        deviceService.useFrontCamera(enable)
    }
    
    // MARK: private method
    private func heartBeatRequest() {
        var request = HeartBeatRequest()
        request.userID = RoomManager.shared.userService.localUserInfo?.userID ?? ""
        RequestManager.shared.heartBeatRequest(request: request) { requestStatus in
        } failure: { requestStatus in
        }
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
    
    func zim(_ zim: ZIM, roomMemberJoined memberList: [ZIMUserInfo], roomID: String) {
        var addUsers: [UserInfo] = []
        for zimUser in memberList {
            let user = UserInfo(zimUser.userID, zimUser.userName)
            addUsers.append(user)
            guard let userID = user.userID else { continue }
            userList.addObj(userID, user)
        }
    }
    
    func zim(_ zim: ZIM, roomMemberLeft memberList: [ZIMUserInfo], roomID: String) {
        var leftUsers: [UserInfo] = []
        for zimUser in memberList {
            let user = UserInfo(zimUser.userID, zimUser.userName)
            leftUsers.append(user)
            guard let userID = user.userID else { continue }
            userList.removeObj(userID)
        }
        
        for obj in delegates.allObjects {
            if let delegate = obj as? UserServiceDelegate {
                delegate.receiveEndCall()
            }
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
            let userInfo: UserInfo = UserInfo()
            userInfo.userID = command.content?.user_info["id"]
            userInfo.userName = command.content?.user_info["name"]
            var callType: CallType = .audio
            if let content = command.content {
                if let type = content.call_type {
                    callType = CallType(rawValue: type) ?? .audio
                }
            }
            for delegate in delegates.allObjects {
                guard let delegate = delegate as? UserServiceDelegate else { continue }
                switch command.type {
                case .call:
                    delegate.receiveCall(userInfo, type: callType)
                case .cancel:
                    guard let cancelType = command.content?.cancel_type else { return }
                    if cancelType == 1 {
                        delegate.receiveCancelCall(userInfo, type: CancelType(rawValue: 1) ?? .intent)
                    } else {
                        delegate.receiveCancelCall(userInfo, type: CancelType(rawValue: cancelType) ?? .timeout)
                    }
                case .reply:
                    if command.content?.response_type == 1 {
                        let streamID = String.getStreamID(localUserInfo?.userID, roomID: roomService.roomInfo.roomID)
                        ZegoExpressEngine.shared().startPublishingStream(streamID)
                        delegate.receiveCallResponse(userInfo, responseType: .accept)
                    } else {
                        roomService.leaveRoom { result in
                            switch result {
                            case .success():
                                delegate.receiveCallResponse(userInfo, responseType: .reject)
                            case .failure(_):
                                break
                            }
                        }
                    }
                case .end:
                    delegate.receiveEndCall()
                }
            }
        }
    }
}

extension UserService: ZegoEventHandler {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        for obj in delegates.allObjects {
            if let delegate = obj as? UserServiceDelegate {
                delegate.onNetworkQuality(userID, upstreamQuality: upstreamQuality)
            }
        }
    }
}

extension UserService: RoomServiceDelegate {
    func receiveRoomInfoUpdate(_ roomAttributes: [String : String]?) {
        guard let roomAttributes = roomAttributes else { return }
        let keys = roomAttributes.keys
        for key in keys {
            if let json = roomAttributes[key] {
                let userRoomInfo = ZegoJsonTool.jsonToModel(type: UserInfo.self, json: json)
                guard let userRoomInfo = userRoomInfo else { return }
                if key == localUserRoomInfo?.userID {
                    localUserRoomInfo?.userName = userRoomInfo.userName
                    localUserRoomInfo?.camera = userRoomInfo.camera
                    localUserRoomInfo?.mic = userRoomInfo.mic
                }
                for obj in delegates.allObjects {
                    if let delegate = obj as? UserServiceDelegate {
                        delegate.userInfoUpdate(userRoomInfo)
                    }
                }
            }
        }
    }
}

