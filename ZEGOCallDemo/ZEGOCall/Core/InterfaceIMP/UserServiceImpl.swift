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
    
    
    private weak var listener = ListenerManager.shared
    
    override init() {
        super.init()
        
        // ServiceManager didn't finish init at this time.
        DispatchQueue.main.async {
            ServiceManager.shared.addExpressEventHandler(self)
        }
    }
}

extension UserServiceImpl: UserService {
    
    func setLocalUser(_ userID: String, userName: String) {
        assert(userID.count <= 64, " The User ID length must be less than or equal to 64.")
        let user = UserInfo(userID, userName)
        self.localUserInfo = user
        if self.userList.compactMap({ $0.userID }).contains(userID) == false {
            self.userList.append(user)
        }
    }
}

extension UserServiceImpl: ZegoEventHandler {
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        delegate?.onNetworkQuality(userID, upstreamQuality: upstreamQuality)
    }
        
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        for user in userList {
            if updateType == .add {
                if self.userList.compactMap({ $0.userID }).contains(user.userID) { continue }
                self.userList.append(UserInfo(user.userID, user.userName))
            } else {
                self.userList = self.userList.filter({ $0.userID != user.userID })
            }
        }
    }
    
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        let userIDs = streamID.components(separatedBy: ["_"])
        if userIDs.count < 2 { return }
        let userID = userIDs[1]
        print("++++++++++++camera state: \(state.rawValue), \(userID)")
        
        if state != .open && state != .disable { return }
        
        guard let remoteUser = self.userList.filter({ $0.userID == userID }).first else { return }
        remoteUser.camera = state == .open
        delegate?.onUserInfoUpdate(remoteUser)
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        let userIDs = streamID.components(separatedBy: ["_"])
        if userIDs.count >= 2 { return }
        let userID = userIDs[1]
        print("++++++++++++mic state: \(state.rawValue), \(userID)")
        
        if state != .open && state != .mute { return }
        
        guard let remoteUser = self.userList.filter({ $0.userID == userID }).first else { return }
        remoteUser.mic = state == .open
        delegate?.onUserInfoUpdate(remoteUser)
    }
}
