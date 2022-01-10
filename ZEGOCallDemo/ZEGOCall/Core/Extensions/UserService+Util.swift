//
//  UserService+Util.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2022/1/8.
//

import Foundation

extension UserService {
    
    var isMyselfHost: Bool {
        guard let hostID = RoomManager.shared.roomService.roomInfo.hostID else { return false }
        guard let userID = localUserInfo?.userID else { return false }
        return hostID == userID
    }
    
    // if the user on the co-host seat
    func isUserOnSeat(_ userID: String?) -> Bool {
        guard let userID = userID else {
            return false
        }

        for seat in RoomManager.shared.userService.coHostList {
            if seat.userID == userID { return true }
        }
        return false
    }
    
    // if the user in the request co-host list.
    func isUserInRequestList(_ userID: String?) -> Bool {
        guard let userID = userID else {
            return false
        }
        for coHostID in RoomManager.shared.userService.requestCoHostList {
            if coHostID == userID { return true }
        }
        return false
    }
}
