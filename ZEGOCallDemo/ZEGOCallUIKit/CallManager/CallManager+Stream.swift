//
//  CallBusiness+Stream.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation
import ZegoExpressEngine

extension CallManager {
    
    // get local user ID
    var localUserID: String {
        ServiceManager.shared.userService.localUserInfo?.userID ?? ""
    }
}
