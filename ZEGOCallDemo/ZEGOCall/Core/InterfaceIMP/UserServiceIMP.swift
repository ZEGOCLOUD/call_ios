//
//  ZegoUserService.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZegoExpressEngine
import AVFoundation


class UserServiceIMP: NSObject, UserService {
    
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
        
        //TODO: login
        let command = LoginCommand()
        command.excute { result in
            if result.isSuccess {
                
            } else {
                
            }
            guard let callback = callback else { return }
        }
    }
    
    
    func logout() {
        //TODO: logout
        
//        ServiceManager.shared.logoutRtcRoom(true)
    }
    
    func getOnlineUserList(callback: UserListCallback?) {
        
    }
}

extension UserServiceIMP: ZegoEventHandler {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        delegate?.onNetworkQuality(userID, upstreamQuality: upstreamQuality)
    }
}
