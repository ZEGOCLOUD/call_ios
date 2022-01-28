//
//  ZegoRoomManager.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZIM
import ZegoExpressEngine

/// Class ZEGOLive business logic management
///
/// Description: This class contains the ZEGOLive business logic, manages the service instances of different modules, and also distributing the data delivered by the SDK.
class RoomManager: NSObject {
    
    /// Get the ZegoRoomManager singleton instance
    ///
    /// Description: This method can be used to get the RoomManager singleton instance.
    ///
    /// Call this method at: Any time
    static let shared = RoomManager()
    
    // MARK: - Private
    private let rtcEventDelegates: NSHashTable<ZegoEventHandler> = NSHashTable(options: .weakMemory)
    private let zimEventDelegates: NSHashTable<ZIMEventHandler> = NSHashTable(options: .weakMemory)
    
    private override init() {
        userService = UserService()
        super.init()
    }
    
    /// The user information management instance, contains the in-room user information management, logged-in user information and other business logic.
    var userService: UserService
    
    /// Initialize the SDK
    ///
    /// Description: This method can be used to initialize the ZIM SDK and the Express-Audio SDK.
    ///
    /// Call this method at: Before you log in. We recommend you call this method when the application starts.
    ///
    /// - Parameter appID: refers to the project ID. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    /// - Parameter appSign: refers to the secret key for authentication. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    func initWithAppID(appID: UInt32, appSign: String, callback: RoomCallback?) {
        if appSign.count == 0 {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        ZIMManager.shared.createZIM(appID: appID)
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.appSign = appSign
        profile.scenario = .general
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)
        
        var result: ZegoResult = .success(())
        if ZIMManager.shared.zim == nil {
            result = .failure(.other(1))
        } else {
            ZIMManager.shared.zim?.setEventHandler(self)
        }
        guard let callback = callback else { return }
        callback(result)
    }
    
    
    /// The method to deinitialize the SDK
    ///
    /// Description: This method can be used to deinitialize the SDK and release the resources it occupies.
    ///
    /// Call this method at: When the SDK is no longer be used. We recommend you call this method when the application exits.
    func uninit() {
        logoutRtcRoom(true)
        ZIMManager.shared.destoryZIM()
        ZegoExpressEngine.destroy(nil)
    }
    
    /// Upload local logs to the ZEGOCLOUD Server
    ///
    /// Description: You can call this method to upload the local logs to the ZEGOCLOUD Server for troubleshooting when exception occurs.
    ///
    /// Call this method at: When exceptions occur
    ///
    /// - Parameter fileName: refers to the name of the file you upload. We recommend you name the file in the format of "appid_platform_timestamp".
    /// - Parameter callback: refers to the callback that be triggered when the logs are upload successfully or failed to upload logs.
    func uploadLog(callback: RoomCallback?) {
        ZIMManager.shared.zim?.uploadLog({ errorCode in
            guard let callback = callback else { return }
            if errorCode.code == .ZIMErrorCodeSuccess {
                callback(.success(()))
            } else {
                callback(.failure(.other(Int32(errorCode.code.rawValue))))
            }
        })
    }
}

extension RoomManager {
    func loginRtcRoom(with rtcToken: String) {
        guard let userID = RoomManager.shared.userService.localUserInfo?.userID else {
            assert(false, "user id can't be nil.")
            return
        }
        
        guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID else {
            assert(false, "room id can't be nil.")
            return
        }
        
        // login rtc room
        let user = ZegoUser(userID: userID)
        
        let config = ZegoRoomConfig()
        config.token = rtcToken
        config.maxMemberCount = 0
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: config)
        
        // monitor sound level
        ZegoExpressEngine.shared().startSoundLevelMonitor(1000)
    }
        
    func logoutRtcRoom(_ containsUserService: Bool = false) {
        ZegoExpressEngine.shared().logoutRoom()
        
        if containsUserService {
            userService = UserService()
        }
        userService.userList = DictionaryArray<String, UserInfo>()
        userService.localUserRoomInfo = nil
    }
    
    // MARK: - event handler
    func addZIMEventHandler(_ eventHandler: ZIMEventHandler?) {
        zimEventDelegates.add(eventHandler)
    }
    
    func addExpressEventHandler(_ eventHandler: ZegoEventHandler?) {
        rtcEventDelegates.add(eventHandler)
    }
}

extension RoomManager: ZegoEventHandler {
    
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        
        for stream in streamList {
            if updateType == .add {
//                ZegoExpressEngine.shared().startPlayingStream(stream.streamID, canvas: nil)
            } else {
                ZegoExpressEngine.shared().stopPlayingStream(stream.streamID)
            }
        }
        
        for delegate in rtcEventDelegates.allObjects {
            delegate.onRoomStreamUpdate?(updateType, streamList: streamList, extendedData: extendedData, roomID: roomID)
        }
    }
    
    func onPlayerStateUpdate(_ state: ZegoPlayerState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onPlayerStateUpdate?(state, errorCode: errorCode, extendedData: extendedData, streamID: streamID)
        }
    }
    
    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onPublisherStateUpdate?(state, errorCode: errorCode, extendedData: extendedData, streamID: streamID)
        }
    }
    
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onNetworkQuality?(userID, upstreamQuality: upstreamQuality, downstreamQuality: downstreamQuality)
        }
    }
}

extension RoomManager: ZIMEventHandler {
    func zim(_ zim: ZIM, connectionStateChanged state: ZIMConnectionState, event: ZIMConnectionEvent, extendedData: [AnyHashable : Any]) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, connectionStateChanged: state, event: event, extendedData: extendedData)
        }
    }
    
    // MARK: - Main
    func zim(_ zim: ZIM, errorInfo: ZIMError) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, errorInfo: errorInfo)
        }
    }
    
    func zim(_ zim: ZIM, tokenWillExpire second: UInt32) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, tokenWillExpire: second)
        }
    }
    
    // MARK: - Message
    func zim(_ zim: ZIM, receivePeerMessage messageList: [ZIMMessage], fromUserID: String) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, receivePeerMessage: messageList, fromUserID: fromUserID)
        }
    }
    
    func zim(_ zim: ZIM, receiveRoomMessage messageList: [ZIMMessage], fromRoomID: String) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, receiveRoomMessage: messageList, fromRoomID: fromRoomID)
        }
    }
    
    // MARK: - Room
    func zim(_ zim: ZIM, roomMemberJoined memberList: [ZIMUserInfo], roomID: String) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, roomMemberJoined: memberList, roomID: roomID)
        }
    }
    
    func zim(_ zim: ZIM, roomMemberLeft memberList: [ZIMUserInfo], roomID: String) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, roomMemberLeft: memberList, roomID: roomID)
        }
    }
    
    func zim(_ zim: ZIM, roomStateChanged state: ZIMRoomState, event: ZIMRoomEvent, extendedData: [AnyHashable : Any], roomID: String) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, roomStateChanged: state, event: event, extendedData: extendedData, roomID: roomID)
        }
    }
    
    func zim(_ zim: ZIM, roomAttributesUpdated updateInfo: ZIMRoomAttributesUpdateInfo, roomID: String) {
        for delegate in zimEventDelegates.allObjects {
            delegate.zim?(zim, roomAttributesUpdated: updateInfo, roomID: roomID)
        }
    }
}
