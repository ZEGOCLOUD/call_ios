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

protocol UserServiceDelegate : AnyObject  {
    
    /// Callbacks related to the user connection status
    ///
    /// Description: This callback will be triggered when user gets disconnected due to network error, or gets offline due to the operations in other clients.
    ///
    /// - Parameter state: refers to the current connection state.
    /// - Parameter event: refers to the the event that causes the connection status changes.
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent)
    
    /// Callback for the network quality
    ///
    /// Description: Callback for the network quality, and this callback will be triggered after the stream publishing or stream playing.     ///
    /// - Parameter userID: Refers to the user ID of the stream publisher or stream subscriber.
    /// - Parameter upstreamQuality: Refers to the stream quality level.
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel)
    
    /// Callback for changes on user state
    ///
    /// Description: This callback will be triggered when the state of the user's microphone/camera changes.
    ///
    /// - Parameter userInfo: refers to the changes on user state information
    func userInfoUpdate(_ userInfo: UserInfo)
    
    /// Callback for receive an incoming call
    ///
    /// Description: This callback will be triggered when receiving an incoming call.
    ///
    /// - Parameter userInfo: refers to the caller information.
    /// - Parameter type: indicates the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    func receiveCallInvite(_ userInfo: UserInfo, type: CallType)
    
    /// Callback for receive a canceled call
    ///
    /// Description: This callback will be triggered when the caller cancel the outbound call.
    ///
    /// - Parameter userInfo: refers to the caller information.
    /// - Parameter type: cancel type.
    func receiveCallCanceled(_ userInfo: UserInfo, type: CancelType)
    
    /// Callback for respond to an incoming call
    ///
    /// Description: This callback will be triggered when the called user responds to an incoming call.
    ///
    /// - Parameter userInfo: refers to the called user information.
    /// - Parameter responseType: indicates to the answer of the incoming call. ZegoResponseTypeAccept: Accept. ZegoResponseTypeDecline: Decline.
    func receiveCallResponse(_ userInfo: UserInfo, responseType: CallResponseType)
    
    /// Callback for end a call
    ///
    /// - Description: This callback will be triggered when the caller or called user ends the call.
    func receiveCallEnded()
}

// default realized
extension UserServiceDelegate {
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent){ }
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel) { }
    func userInfoUpdate(_ userInfo: UserInfo) { }
    func receiveCallInvite(_ userInfo: UserInfo , type: CallType) { }
    func receiveCallCanceled(_ userInfo: UserInfo, type: CancelType) { }
    func receiveCallResponse(_ userInfo: UserInfo , responseType: CallResponseType) { }
    func receiveCallEnded() { }
}


/// Class user information management
///
/// Description: This class contains the user information management logic, such as the logic of log in, log out, get the logged-in user info, get the in-room user list, and add co-hosts, etc.
class UserService: NSObject {
    
    // MARK: - Public
    /// The delegate related to user status
    var delegates = NSHashTable<AnyObject>.weakObjects()
    
    /// The local logged-in user information.
    var localUserInfo: UserInfo?
    
    /// In-room user list, can be used when displaying the user list in the room.
    var userList = DictionaryArray<String, UserInfo>()
    
    var localUserRoomInfo: UserInfo?
    var roomService: RoomService = RoomService()
    
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
    
    /// User to log in
    ///
    /// Description: Call this method with user ID and username to log in to the LiveAudioRoom service.
    ///
    /// Call this method at: After the SDK initialization
    ///
    /// - Parameter userInfo: refers to the user information. You only need to enter the user ID and username.
    /// - Parameter token: refers to the authentication token. To get this, refer to the documentation: https://doc-en.zego.im/article/11648
    /// - Parameter callback: refers to the callback for log in.
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
    
    
    /// User to log out
    ///
    /// - Description: This method can be used to log out from the current user account.
    ///
    /// Call this method at: After the user login
    func logout() {
        ZIMManager.shared.zim?.logout()
        RoomManager.shared.logoutRtcRoom(true)
    }
    
    
    /// Make an outbound call
    ///
    /// Description: This method can be used to initiate a call to a online user. The called user receives a notification once this method gets called. And if the call is not answered in 60 seconds, you will need to call a method to cancel the call.
    ///
    /// Call this method at: After the user login
    /// - Parameter userID: refers to the ID of the user you want call.
    /// - Parameter token: refers to the authentication token. To get this, see the documentation: https://docs.zegocloud.com/article/11648
    /// - Parameter type: refers to the call type.  ZegoCallTypeVoice: Voice call.  ZegoCallTypeVideo: Video call.
    /// - Parameter callback: refers to the callback for make a outbound call.
    func callUser(_ userID: String, token: String, type: CallType, callback: RoomCallback?) {
        guard let myUserID = localUserInfo?.userID else { return }
        guard let myUserName = localUserInfo?.userName else { return }
        roomService.createRoom(myUserID, myUserName, token) { [self] result in
            localUserRoomInfo = UserInfo(myUserID,myUserName)
            localUserRoomInfo?.voice = false
            self.enableSpeaker(false)
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
    
    /// Cancel a call
    ///
    /// Description: This method can be used to cancel a call. And the called user receives a notification through callback that the call has been canceled.
    ///
    /// Call this method at: After the user login
    /// - Parameter userID: refers to the ID of the user you are calling.
    /// - Parameter cancelType: cancel type
    /// - Parameter callback: refers to the callback for cancel a call.
    func cancelCall(userID: String, cancelType: CancelType, callback: RoomCallback?) {
        sendPeerMesssage(userID, callType: nil, cancelType: cancelType, commandType: .cancel, responseType: .none) { result in
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
    
    /// Respond to an incoming call
    ///
    /// Description: This method can be used to accept or decline an incoming call. You will need to call this method to respond to the call within 60 seconds upon receiving.
    ///
    /// Call this method at: After the user login
    /// - Parameter userID: refers to the ID of the caller.
    /// - Parameter responseType: refers to the answer of the incoming call.  ZegoResponseTypeAccept: Accept. ZegoResponseTypeDecline: Decline.
    /// - Parameter callback: refers to the callback for respond to an incoming call.
    func respondCall(_ userID: String, token:String, responseType: CallResponseType, callback: RoomCallback?) {
        if responseType == .accept {
            self.roomService.joinRoom(userID, token) { result in
                switch result {
                case .success():
                    ///start publish
                    guard let myUserID = self.localUserInfo?.userID else { return }
                    self.localUserRoomInfo = UserInfo(myUserID,self.localUserInfo?.userName ?? "")
                    self.localUserRoomInfo?.voice = false
                    let streamID = String.getStreamID(myUserID, roomID: userID)
                    ZegoExpressEngine.shared().startPublishingStream(streamID)
                    self.enableSpeaker(false)
                    ///send peer message
                    self.sendPeerMesssage(userID, callType: nil, cancelType: nil, commandType: .reply, responseType: responseType, callback: callback)
                case .failure(let error):
                    guard let callback = callback else { return }
                    let result: ZegoResult = .failure(.other(Int32(error.code)))
                    callback(result)
                }
            }
        } else {
            sendPeerMesssage(userID, callType: nil, cancelType: nil, commandType: .reply, responseType: .decline, callback: callback)
        }
    }
    
    
    /// End a call
    ///
    /// Description: This method can be used to end a call. After the call is ended, both the caller and called user will be logged out from the room, and the stream publishing and playing stop upon ending.
    ///
    /// Call this method at: After the user login
    /// - Parameter callback refers to the callback for end a call.
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
    
    /// Microphone related operation
    ///
    /// Description: This method can be used to enable and disable the microphone. When the microphone is enabled, the SDK automatically publishes audio streams to remote users. When the microphone is disabled, the audio stream publishing stops automatically.
    ///
    /// Call this method at: After the call is connected
    ///
    /// - Parameter enable: indicates whether to enable or disable the microphone. true: Enable. false: Disable.
    /// - Parameter callback: refers to the callback for enable or disable the microphone.
    func enableMic(_ enable: Bool, callback: RoomCallback?) {
        
        guard let parameters = getDeviceChangeParameters(enable, flag: 0) else {
            return
        }
        
        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
        // open mic
        muteMicrophone(!enable)
    }
    
    /// Camera related operation
    ///
    /// Description: This method can be used to enable and disable the camera. When the camera is enabled, the SDK automatically publishes video streams to remote users. When the camera is disabled, the video stream publishing stops automatically.
    ///
    /// Call this method at:  After the call is connected
    ///
    /// - Parameter enable: indicates whether to enable or disable the camera. true: Enable. false: Disable.
    /// - Parameter callback: refers to the callback for enable or disable the camera.
    func enableCamera(_ enable: Bool, callback: RoomCallback?) {
        
        guard let parameters = getDeviceChangeParameters(enable, flag: 1) else {
            return
        }
        
        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
        // open camera
        enableCamera(enable)
    }
}

// MARK: - Private
extension UserService {
    
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
                delegate.receiveCallEnded()
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
            var callType: CallType = .voice
            if let content = command.content {
                if let type = content.call_type {
                    callType = CallType(rawValue: type) ?? .voice
                }
            }
            for delegate in delegates.allObjects {
                guard let delegate = delegate as? UserServiceDelegate else { continue }
                switch command.type {
                case .call:
                    delegate.receiveCallInvite(userInfo, type: callType)
                case .cancel:
                    guard let cancelType = command.content?.cancel_type else { return }
                    if cancelType == 1 {
                        delegate.receiveCallCanceled(userInfo, type: CancelType(rawValue: 1) ?? .intent)
                    } else {
                        delegate.receiveCallCanceled(userInfo, type: CancelType(rawValue: cancelType) ?? .timeout)
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
                                delegate.receiveCallResponse(userInfo, responseType: .decline)
                            case .failure(_):
                                break
                            }
                        }
                    }
                case .end:
                    delegate.receiveCallEnded()
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

