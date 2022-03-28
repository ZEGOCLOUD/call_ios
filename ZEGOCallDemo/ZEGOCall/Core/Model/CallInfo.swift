//
//  CallInfo.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

class CallInfo: NSObject {
    /// 一个通话的标识
    var callID: String?
    /// 呼叫者的用户信息
    var caller: UserInfo?
    /// 被呼叫者的用户信息
    var callees = [UserInfo]()
}
