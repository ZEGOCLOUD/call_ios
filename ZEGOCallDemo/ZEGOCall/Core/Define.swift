//
//  ZegoDefine.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation

typealias ZegoResult = Result<Void, ZegoError>

/// Callback methods
///
/// Description: When the called method is asynchronous processing, If you are making and processing asynchronous calls,
/// the following callbacks will be triggered when a method has finished its execution and returns the execution result.
///
/// @param error refers to the operation status code.
///            0: Operation successful.
///            100xxxx: The Express SDK error code. For details, refer to the error code documentation. [iOS]: https://doc-en.zego.im/article/5547 [Android]: https://doc-en.zego.im/article/5548
///            600xxxx: The ZIM SDK error code. For details, refer to the error code documentation. [iOS]: https://docs.zegocloud.com/article/13791 [Android]: https://docs.zegocloud.com/article/13792
typealias RoomCallback = (ZegoResult) -> Void

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
    case decline = 2
}

enum CancelType: Int {
    case intent = 1
    case timeout = 2
}

enum CallType: Int {
    case voice = 1
    case video = 2
}
