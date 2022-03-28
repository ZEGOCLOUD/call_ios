//
//  CallInfo.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

class CallInfo: NSObject {
    /// A call identify, To initiate a call, a callID is generated
    var callID: String?
    /// Information about the user who initiates the call
    var caller: UserInfo?
    /// User information of the called user
    var callees = [UserInfo]()
}
