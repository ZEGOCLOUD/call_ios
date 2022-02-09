//
//  CallMainVC+Stream.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import Foundation
import ZegoExpressEngine

extension CallMainVC {
    
    // get local user ID
    var localUserID: String {
        RoomManager.shared.userService.localUserInfo?.userID ?? ""
    }
        
    func isUserMyself(_ userID: String?) -> Bool {
        return localUserID == userID
    }
    
    func getRoomID() -> String {
        return RoomManager.shared.userService.roomService.roomInfo.roomID ?? ""
    }
}


