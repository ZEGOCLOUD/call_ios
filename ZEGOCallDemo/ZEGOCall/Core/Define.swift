//
//  ZegoDefine.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation

typealias ZegoResult = Result<Void, ZegoError>
/// common room callback
typealias RoomCallback = (ZegoResult) -> Void

typealias UserIDCallBack = (Result<String, ZegoError>) -> Void

/// online room users count callback
typealias OnlineRoomUsersCountCallback = (Result<UInt32, ZegoError>) -> Void

/// online room users callback
typealias OnlineRoomUsersCallback = (Result<[UserInfo], ZegoError>) -> Void

/// room list callback
typealias UserListCallback = (Result<[UserInfo], ZegoError>) -> Void


enum ZegoError: Error {
        
    /// common failed
    case failed
    case paramInvalid
    
    /// other error code
    case other(_ rawValue: Int32)
    
    var code: Int32 {
        switch self {
        case .failed: return 1
        case .paramInvalid: return 2001
        case .other(let rawValue): return rawValue
        }
    }
}

enum CallResponseType: Int {
    case accept = 1
    case reject = 2
}

enum CancelType: Int {
    case intent = 1
    case timeout = 2
}

enum CallType: Int {
    case audio = 1
    case video = 2
}
