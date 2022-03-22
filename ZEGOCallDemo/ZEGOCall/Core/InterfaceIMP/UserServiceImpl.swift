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
            
        }
    }
}

extension UserServiceImpl: UserService {
    func login(_ token: String, callback: RoomCallback?) {
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
    
    func getOnlineUserList(_ callback: UserListCallback?) {
        
        userListCommand.excute { result in
            var listResult: Result<[UserInfo], ZegoError> = .failure(.failed)
            switch result {
            case .success(let json):
                //TODO: add users
                break
            case .failure(let error):
                listResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(listResult)
        }
    }
}

extension UserServiceImpl {
    private func registerListener() {
        listener?.registerListener(self, for: Notify_User_Error, callback: { result in
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
}
