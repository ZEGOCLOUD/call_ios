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
        ServiceManager.shared.userService.localUserInfo?.userID ?? ""
    }
}


