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

/// room list callback
typealias UserListCallback = (Result<[UserInfo], ZegoError>) -> Void

typealias RequestCallback = (Result<Any, ZegoError>) -> Void

typealias NotifyCallback = ([String : Any]) -> Void


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

enum DeclineType: Int {
    case decline = 1
    case busy = 2
}

enum CancelType: Int {
    case intent = 1
}

enum CallType: Int {
    case voice = 1
    case video = 2
}

enum LocalUserStatus: Int {
    case free = 0
    case outgoing = 1
    case incoming = 2
    case calling = 3
}

/// Class video resolution
///
/// Description: This class contains the video resolution information. To set the video resolution, call the setVideoResolution method.
enum VideoResolution: Int {
    /// 1080P: 1920 * 1080
    case p1080
    
    /// 720P: 1280 * 720
    case p720
    
    /// 540P: 960 * 540
    case p540
    
    /// 360P: 640 * 360
    case p360
    
    /// 270P: 480 * 270
    case p270
    
    /// 180P: 320 * 180
    case p180
}

/// Class audio bitrate
///
/// Description: This class contains the audio bitrate information. To set the audio bitrate, call the setAudioBitrate method.
enum AudioBitrate: Int {
    /// 16kbps
    case b16
    
    /// 48kbps
    case b48
    
    /// 56kbps
    case b56
    
    /// 96kbps
    case b96
    
    /// 128kbps
    case b128
    
    /// 192kbps
    case b192
}

/// Class device settings
///
/// Description: This class contains the device settings related information for you to configure different device settings.
enum DeviceType {
    
    /// Noise suppression
    case noiseSuppression
    
    /// Echo cancellation
    case echoCancellation
    
    /// Volume auto-adjustment
    case volumeAdjustment
    
    ///  video Mirror
    case videoMirror
    
    /// Video resolution
    case videoResolution
    
    /// Audio bitrate
    case bitrate
}

enum CallTimeoutType {
    case caller
    case callee
}

enum UserError: Int {
    case kickedOut = 1
}


let API_Login = "/user/login"
let API_Logout = "/user/logout"
let API_GetUser = "/user/get"
let API_Get_Users = "/user/get_users"
let API_Call_Heartbeat = "/call/heartbeat"
let API_Start_Call = "/call/start_call"
let API_Cancel_Call = "/call/cancel_call"
let API_Accept_Call = "/call/accept_call"
let API_Decline_Call = "/call/decline_call"
let API_End_Call = "/call/end_call"

let Notify_Call_Invited = "/call/notify_call_invited"
let Notify_Call_Canceled = "/call/notify_call_canceled"
let Notify_Call_Response = "/call/notify_call_response"
let Notify_Call_Accept = "/call/notify_call_accept"
let Notify_Call_Decline = "/call/notify_call_decline"
let Notify_Call_End = "/call/notify_call_end"
let Notify_Call_Timeout = "/call/notify_timeout"
let Notify_User_Error = "/user/notify_error"
