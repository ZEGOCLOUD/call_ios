//
//  ZegoUserService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZIM
import ZegoExpressEngine

enum CoHostChangeType {
    case add
    case leave
    case remove
    case mic
    case camera
    case mute
}

protocol UserServiceDelegate : AnyObject  {
    func connectionStateChanged(_ state: ZIMConnectionState, _ event: ZIMConnectionEvent)
    /// receive user join room
    func roomUserJoin(_ users: [UserInfo])
    /// reveive user leave room
    func roomUserLeave(_ users: [UserInfo])
    /// receive custom command: invitation
    func receiveAddCoHostInvitation()
    /// receive add co-host invitation respond
    func receiveAddCoHostRespond(_ userInfo: UserInfo, accept: Bool)
    /// receive request to co-host request
    func receiveToCoHostRequest(_ userInfo: UserInfo)
    /// receive cancel request to co-host
    func receiveCancelToCoHostRequest(_ userInfo: UserInfo)
    /// receive response to request to co-host
    func receiveToCoHostRespond(_ agree: Bool)
    
    func coHostChange(_ targetUserID: String, type: CoHostChangeType)
}

// default realized
extension UserServiceDelegate {
    func roomUserJoin(_ users: [UserInfo]) { }
    func roomUserLeave(_ users: [UserInfo]) { }
    func receiveAddCoHostInvitation() { }
    func receiveAddCoHostRespond(_ userInfo: UserInfo, accept: Bool) { }
    func receiveToCoHostRequest(_ userInfo: UserInfo) { }
    func receiveCancelToCoHostRequest(_ userInfo: UserInfo) { }
    func receiveToCoHostRespond() { }
    func coHostChange(_ targetUserID: String, type: CoHostChangeType) { }
}

class UserService: NSObject {
    // MARK: - Public
    let delegates = NSHashTable<AnyObject>.weakObjects()
    var localUserInfo: UserInfo?
    var userList = DictionaryArray<String, UserInfo>()
    var coHostList: [CoHostModel] {
        RoomManager.shared.roomService.operation.coHost
    }
    var requestCoHostList: [String] {
        RoomManager.shared.roomService.operation.requestCoHost
    }
    
    override init() {
        super.init()
        
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
        
    /// get the number of chat rooms available online
    func getOnlineRoomUsersNum(callback: OnlineRoomUsersCountCallback?) {
        guard let roomID = RoomManager.shared.roomService.roomInfo.roomID else {
            assert(false, "room ID can't be nil")
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        ZIMManager.shared.zim?.queryRoomOnlineMemberCount(roomID, callback: { count, error in
            var result: Result<UInt32, ZegoError>
            if error.code == .ZIMErrorCodeSuccess {
                result = .success(count)
            } else {
                result = .failure(.other(Int32(error.code.rawValue)))
            }
            guard let callback = callback else { return }
            callback(result)
        })
    }
    
    /// get users of target page.
    func getOnlineRoomUsers(_ nextFlag: String?, callback: OnlineRoomUsersCallback?) {
        guard let roomID = RoomManager.shared.roomService.roomInfo.roomID else {
            assert(false, "room ID can't be nil")
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        let config = ZIMQueryMemberConfig()
        config.count = 100
        config.nextFlag = nextFlag ?? ""
        ZIMManager.shared.zim?.queryRoomMember(roomID, config: config, callback: { zimUsers, nextFlag, error in
            
            if error.code != .ZIMErrorCodeSuccess {
                guard let callback = callback else { return }
                callback(.failure(.other(Int32(error.code.rawValue))))
                return
            }
            var users: [UserInfo] = []
            
            for zimUser in zimUsers {
                let role: UserRole = zimUser.userID == RoomManager.shared.roomService.roomInfo.hostID ? .host : .participant
                let user = UserInfo(zimUser.userID, zimUser.userName, role)
                users.append(user)
            }
            guard let callback = callback else { return }
            callback(.success(users))
        })
    }
    
    /// send an invitation message to add co-host
    func addCoHost(_ userID: String, callback: RoomCallback?) {
        let invitation = CustomCommand(.invitation)
        invitation.targetUserIDs.append(userID)
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
                if let user = self.userList.getObj(userID) {
                    user.hasInvited = true
                }
            } else {
                result = .failure(.other(Int32(error.code.rawValue)))
            }
            guard let callback = callback else { return }
            callback(result)
        })
    }
    
    /// respond to the co-host invitation
    func respondCoHostInvitation(_ accept: Bool, callback: RoomCallback?) {
        guard let userID = RoomManager.shared.userService.localUserInfo?.userID else { return }
        guard let hostID = RoomManager.shared.roomService.roomInfo.hostID else {
            assert(false, "the room ID can't be nil")
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        let respond = CustomCommand(.respondInvitation)
        respond.targetUserIDs.append(userID)
        respond.content = CustomCommandContent(accept: accept)
        
        guard let json = respond.json(),
              let data = json.data(using: .utf8) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        let customMessage: ZIMCustomMessage = ZIMCustomMessage(message: data)
        ZIMManager.shared.zim?.sendPeerMessage(customMessage, toUserID: hostID, callback: { _, error in
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
    
    /// the participant request to host to be a co-host
    func requestToCoHost(callback: RoomCallback?) {
        guard let parameters = getRequestOrCancelToHostParameters(localUserInfo?.userID, isRequest: true) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        setRoomAttributes(parameters.0, parameters.1, parameters.2, callback)
    }
    
    func cancelRequestToCoHost(callback: RoomCallback?) {
        cancelRequestToCoHost(localUserInfo?.userID, callback: callback)
    }
    // private method, host can use this method to cancel request
    private func cancelRequestToCoHost(_ userID: String?, callback: RoomCallback?) {
        guard let parameters = getRequestOrCancelToHostParameters(userID, isRequest: false) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        setRoomAttributes(parameters.0, parameters.1, parameters.2, callback)
    }
    
    /// the host respond to the participant
    func respondCoHostRequest(_ agree: Bool, _ userID: String, callback: RoomCallback?) {
        // remove user ID from coHost
        guard let parameters = getRespondCoHostParameters(agree, userID: userID) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        setRoomAttributes(parameters.0, parameters.1, parameters.2, callback)
    }
    
    /// take to co-host seat
    func takeCoHostSeat(callback: RoomCallback?) {
        guard let parameters = getTakeOrLeaveSeatParameters(localUserInfo?.userID, isTake: true) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        // publish stream
        guard let myUserID = localUserInfo?.userID else { return }
        let streamID = String.getStreamID(myUserID, roomID: parameters.1)
        ZegoExpressEngine.shared().startPublishingStream(streamID)
        
        setRoomAttributes(parameters.0, parameters.1, parameters.2, callback)
    }
    
    
    /// leave co-host seat
    func leaveCoHostSeat(callback: RoomCallback?) {
        removeUserFromSeat(localUserInfo?.userID, callback: callback)
    }
    
    func removeUserFromSeat(_ userID: String?, callback: RoomCallback?) {
        guard let parameters = getTakeOrLeaveSeatParameters(userID, isTake: false) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        setRoomAttributes(parameters.0, parameters.1, parameters.2, callback)
    }
        
    /// prohibit turning on the mic
    func muteUser(_ isMuted: Bool, userID: String, callback: RoomCallback?) {
        guard let hostID = RoomManager.shared.roomService.roomInfo.hostID,
              let myUserID = localUserInfo?.userID
        else {
            assert(false, "the hostID or roomID cannot be nil")
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        // only the host have access to call this method
        if hostID != myUserID {
            guard let callback = callback else { return }
            callback(.failure(.noPermission))
            return
        }
        
        guard let parameters = getSeatChangeParameters(userID ,enable: isMuted, flag: 2) else {
            guard let callback = callback else { return }
            callback(.failure(.failed))
            return
        }
        
        setRoomAttributes(parameters.0, parameters.1, parameters.2, callback)
    }
    
    /// mic operation
    func micOperation(_ open: Bool) {
        
        guard let parameters = getSeatChangeParameters(localUserInfo?.userID, enable: open, flag: 0) else {
            return
        }
        
        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
        // open mic
        ZegoExpressEngine.shared().muteMicrophone(!open)
    }
    
    /// camera operation
    func cameraOpen(_ open: Bool) {
        
        guard let parameters = getSeatChangeParameters(localUserInfo?.userID, enable: open, flag: 1) else {
            return
        }
        
        setRoomAttributes(parameters.0, parameters.1, parameters.2, nil)
        
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
    
    func zim(_ zim: ZIM, roomMemberJoined memberList: [ZIMUserInfo], roomID: String) {
        var addUsers: [UserInfo] = []
        for zimUser in memberList {
            let role: UserRole = zimUser.userID == RoomManager.shared.roomService.roomInfo.hostID ? .host : .participant
            let user = UserInfo(zimUser.userID, zimUser.userName, role)
            addUsers.append(user)
            guard let userID = user.userID else { continue }
            userList.addObj(userID, user)
            if localUserInfo?.userID == userID {
                localUserInfo = user
            }
        }
        
        for obj in delegates.allObjects {
            if let delegate = obj as? UserServiceDelegate {
                delegate.roomUserJoin(addUsers)
            }
        }
    }
    
    func zim(_ zim: ZIM, roomMemberLeft memberList: [ZIMUserInfo], roomID: String) {
        var leftUsers: [UserInfo] = []
        for zimUser in memberList {
            let role: UserRole = zimUser.userID == RoomManager.shared.roomService.roomInfo.hostID ? .host : .participant
            let user = UserInfo(zimUser.userID, zimUser.userName, role)
            leftUsers.append(user)
            guard let userID = user.userID else { continue }
            userList.removeObj(userID)
        }
        
        for obj in delegates.allObjects {
            if let delegate = obj as? UserServiceDelegate {
                delegate.roomUserLeave(leftUsers)
            }
        }
        
        // if the host receive user leave callback,
        // the host must remove the user from seat list and request list.
        if !isMyselfHost { return }
        for leftUser in leftUsers {
            if isUserInRequestList(leftUser.userID) {
                cancelRequestToCoHost(leftUser.userID, callback: nil)
            }
            if isUserOnSeat(leftUser.userID) {
                removeUserFromSeat(leftUser.userID, callback: nil)
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
            
            
            for delegate in delegates.allObjects {
                guard let delegate = delegate as? UserServiceDelegate else { continue }
                if command.type == .invitation {
                    delegate.receiveAddCoHostInvitation()
                } else {
                    guard let accept = command.content?.accept else { continue }
                    if let user = self.userList.getObj(command.targetUserIDs.first ?? "") {
                        delegate.receiveAddCoHostRespond(user, accept: accept)
                    }
                }
            }
        }
    }
}
