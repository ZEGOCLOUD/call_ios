//
//  CallInfo.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

class CallInfo: NSObject {
    /// The ID of the call.
    var callID: String?
    /// The information of the caller.
    var caller: UserInfo?
    /// The information of the callee.
    var callees = [UserInfo]()
}
