//
//  ZegoUserService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZegoExpressEngine
import AVFoundation


class UserServiceImpl: NSObject {
    
    // MARK: - Public
    /// The delegate related to user status
    weak var delegate: UserServiceDelegate?
    
    /// The local logged-in user information.
    private var _localUserInfo: UserInfo?
    var localUserInfo: UserInfo? {
        get {
            if _localUserInfo != nil {
                return _localUserInfo
            } else {
                var user: UserInfo?
                getUserCommand.excute { result in
                    if result.isFailure { return }
                    guard let userDict = result.success as? [String : String] else { return }
                    guard let userID = userDict["id"] else { return }
                    let userName = userDict["name"] ?? ""
                    user = UserInfo(userID, userName)
                }
                _localUserInfo = user
                if user != nil && !userList.compactMap({ $0.userID }).contains(user?.userID) {
                    userList.append(user!)
                }
                return user
            }
        }
    }
    
    /// In-room user list, can be used when displaying the user list in the room.
    var userList = [UserInfo]()
    
    // request command
    private let getUserCommand = GetUserCommand()
    private let loginCommand = LoginCommand()
    private let logoutCommand = LogoutCommand()
    private let userListCommand = UserListCommand()
    
    private weak var listener = ListenerManager.shared
    
    override init() {
        super.init()
        
        registerListener()
        
        // ServiceManager didn't finish init at this time.
        DispatchQueue.main.async {
            ServiceManager.shared.addExpressEventHandler(self)
        }
    }
}

extension UserServiceImpl: UserService {
    func login(_ token: String, callback: ZegoCallback?) {
        loginCommand.token = token
        loginCommand.excute { result in
            var loginResult: ZegoResult = .success(())
            switch result {
            case .success(let dict):
                let userDict = dict as! [String : String]
                let userID = userDict["id"] ?? ""
                let userName = userDict["name"] ?? ""
                self._localUserInfo = UserInfo(userID: userID, userName: userName)
            case .failure(let error):
                loginResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(loginResult)
        }
    }
    
    
    func logout() {
        logoutCommand.excute(callback: nil)
    }
    
    func getToken(_ userID: String, callback: RequestCallback?) {
        
        func realGetToken(tokenCallback: RequestCallback?) {
            let command = TokenCommand()
            command.userID = userID
            // 24h
            let effectiveTimeInSeconds = 24 * 3600
            command.effectiveTimeInSeconds = effectiveTimeInSeconds
            
            command.excute { result in
                var tokenResult: Result<Any, ZegoError> = .failure(.failed)
                switch result {
                case .success(let dict):
                    if let dict = dict as? [String: Any] {
                        if let token = dict["token"] as? String {
                            tokenResult = .success(token)
                            TokenManager.shared.saveToken(token, effectiveTimeInSeconds)
                        }
                    }
                case .failure(let error):
                    tokenResult = .failure(error)
                }
                guard let tokenCallback = tokenCallback else { return }
                tokenCallback(tokenResult)
            }
        }
        
        guard let token = TokenManager.shared.token,
              token.isTokenValid()
        else {
            realGetToken(tokenCallback: callback)
            return
        }
        
        if let callback = callback {
            callback(.success(token.token))
        }
        
        if TokenManager.shared.needUpdateToken() {
            realGetToken(tokenCallback: nil)
        }
    }
    
    func getOnlineUserList(_ callback: UserListCallback?) {
        
        userListCommand.excute { result in
            var listResult: Result<[UserInfo], ZegoError> = .failure(.failed)
            defer {
                if callback != nil {
                    callback!(listResult)
                }
            }
            
            switch result {
            case .success(let userDicts):
                guard let userDicts = userDicts as? [[String: Any]] else { return }
                var users = [UserInfo]()
                for userDict in userDicts {
                    let user = UserInfo()
                    user.userID = userDict["user_id"] as? String
                    user.userName = userDict["display_name"] as? String
                    if user.userID == self.localUserInfo?.userID { continue }
                    users.append(user)
                }
                self.userList = users
                listResult = .success(users)
            case .failure(let error):
                listResult = .failure(error)
            }
        }
    }
}

extension UserServiceImpl {
    private func registerListener() {
        _ = listener?.addListener(Notify_User_Error, listener: { result in
            guard let code = result["error"] as? Int else { return }
            guard let error = UserError.init(rawValue: code) else { return }
            self.delegate?.onReceiveUserError(error)
        })
    }
}

extension UserServiceImpl: ZegoEventHandler {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        delegate?.onNetworkQuality(userID, upstreamQuality: upstreamQuality)
    }
    
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        let userIDs = streamID.components(separatedBy: ["_"])
        if userIDs.count < 2 { return }
        let userID = userIDs[1]
        print("++++++++++++camera state: \(state.rawValue), \(userID)")
        
        if state != .open && state != .disable { return }
        
        var remoteUser: UserInfo?
        if userID == ServiceManager.shared.callService.callInfo.caller?.userID {
            remoteUser = ServiceManager.shared.callService.callInfo.caller
        } else {
            remoteUser = ServiceManager.shared.callService.callInfo.callees.filter({ $0.userID == userID }).first
        }
        remoteUser?.camera = state == .open
        guard let remoteUser = remoteUser else { return }
        delegate?.onUserInfoUpdate(remoteUser)
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        let userIDs = streamID.components(separatedBy: ["_"])
        if userIDs.count >= 2 { return }
        let userID = userIDs[1]
        print("++++++++++++mic state: \(state.rawValue), \(userID)")
        
        if state != .open && state != .mute { return }
        
        var remoteUser: UserInfo?
        if userID == ServiceManager.shared.callService.callInfo.caller?.userID {
            remoteUser = ServiceManager.shared.callService.callInfo.caller
        } else {
            remoteUser = ServiceManager.shared.callService.callInfo.callees.filter({ $0.userID == userID }).first
        }
        remoteUser?.mic = state == .open
        guard let remoteUser = remoteUser else { return }
        delegate?.onUserInfoUpdate(remoteUser)
    }
}
