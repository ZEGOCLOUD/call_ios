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
    var localUserInfo: UserInfo?
    
    /// In-room user list, can be used when displaying the user list in the room.
    var userList = [UserInfo]()
    
    override init() {
        super.init()
        // ServiceManager didn't finish init at this time.
        DispatchQueue.main.async {
            
        }
    }
}

extension UserServiceImpl: UserService {
    func login(_ callback: RoomCallback?) {
        
        let command = LoginCommand()
        
        command.excute { result in
            var loginResult: ZegoResult = .success(())
            switch result {
            case .success(let dict):
                //TODO: login success, add user info
                break
            case .failure(let error):
                loginResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(loginResult)
        }
    }
    
    
    func logout(_ callback: RoomCallback?) {
        
        let command = LogoutCommand()
        command.excute { result in
            var logoutResult: ZegoResult = .success(())
            if result.isFailure {
                logoutResult = .failure(result.failure!)
            }
            guard let callback = callback else { return }
            callback(logoutResult)
        }
    }
    
    func getOnlineUserList(_ callback: UserListCallback?) {
        let command = UserListCommand()
        command.excute { result in
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

extension UserServiceImpl: ZegoEventHandler {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        delegate?.onNetworkQuality(userID, upstreamQuality: upstreamQuality)
    }
}
