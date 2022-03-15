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
}

enum CallType: Int {
    case voice = 1
    case video = 2
}

enum CallStatus: Int {
    case free = 0
    case outgoing = 1
    case incoming = 2
    case calling = 3
}

/// Class video resolution
///
/// Description: This class contains the video resolution information. To set the video resolution, call the setVideoResolution method.
enum ZegoVideoResolution: Int {
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
enum ZegoAudioBitrate: Int {
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
enum ZegoDeviceType {
    
    /// Noise suppression
    case noiseSuppression
    
    /// Echo cancellation
    case echoCancellation
    
    /// Volume auto-adjustment
    case volumeAdjustment
}
