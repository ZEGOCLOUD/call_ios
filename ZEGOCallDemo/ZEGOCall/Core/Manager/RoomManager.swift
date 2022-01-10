//
//  ZegoRoomManager.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZIM
import ZegoExpressEngine
import ZegoEffects

class RoomManager: NSObject {
    static let shared = RoomManager()
    
    // MARK: - Private
    private let rtcEventDelegates: NSHashTable<ZegoEventHandler> = NSHashTable(options: .weakMemory)
    private let zimEventDelegates: NSHashTable<ZIMEventHandler> = NSHashTable(options: .weakMemory)
    
    private override init() {
        roomService = RoomService()
        userService = UserService()
        messageService = MessageService()
        roomListService = RoomListService()
        beautifyService = FaceBeautifyService()
        soundService = SoundEffectService()
        deviceService = DeviceService()
        super.init()
    }
    
    // MARK: - Public
    var roomService: RoomService
    var userService: UserService
    var messageService: MessageService
    var roomListService: RoomListService
    var beautifyService: FaceBeautifyService
    var soundService: SoundEffectService
    var deviceService: DeviceService
    
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
        
        EffectsLicense.shared.getLicense(appID, appSign: appSign)
        
        let faceDetectionModelPath = Bundle.main.path(forResource: "FaceDetectionModel", ofType: "model") ?? ""
        let segmentationModelPath = Bundle.main.path(forResource: "SegmentationModel", ofType: "model") ?? ""
        let whitenBundlePath = Bundle.main.path(forResource: "FaceWhiteningResources", ofType: "bundle") ?? ""
        let commonBundlePath = Bundle.main.path(forResource: "CommonResources", ofType: "bundle") ?? ""
        let rosyBundlePath = Bundle.main.path(forResource: "RosyResources", ofType: "bundle") ?? ""
        let teethWhiteningBundlePath = Bundle.main.path(forResource: "TeethWhiteningResources", ofType: "bundle") ?? ""
        let pathArray: Array<String> = [faceDetectionModelPath, segmentationModelPath, whitenBundlePath, commonBundlePath, rosyBundlePath, teethWhiteningBundlePath]
        ZegoEffects.setResources(pathArray)
        
        let processConfig = ZegoCustomVideoProcessConfig()
        processConfig.bufferType = .cvPixelBuffer
        ZegoExpressEngine.shared().enableCustomVideoProcessing(true, config: processConfig)
        ZegoExpressEngine.shared().setCustomVideoProcessHandler(self)
        
        var result: ZegoResult = .success(())
        if ZIMManager.shared.zim == nil {
            result = .failure(.other(1))
        } else {
            ZIMManager.shared.zim?.setEventHandler(self)
        }
        guard let callback = callback else { return }
        callback(result)
    }
    
    func uninit() {
        logoutRtcRoom(true)
        ZIMManager.shared.destoryZIM()
        ZegoExpressEngine.destroy(nil)
    }
    
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
        
        guard let roomID = RoomManager.shared.roomService.roomInfo.roomID else {
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
            roomListService = RoomListService()
        }
        roomService = RoomService()
        messageService = MessageService()
        userService.userList = DictionaryArray<String, UserInfo>()
        userService.localUserInfo?.role = .participant
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
    
    func onCapturedSoundLevelUpdate(_ soundLevel: NSNumber) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onCapturedSoundLevelUpdate?(soundLevel)
        }
    }
    
    func onRemoteSoundLevelUpdate(_ soundLevels: [String : NSNumber]) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onRemoteSoundLevelUpdate?(soundLevels)
        }
    }
    
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

extension RoomManager: ZegoCustomVideoProcessHandler {
    
    func onStart(_ channel: ZegoPublishChannel) {
        self.beautifyService.effects.initEnv(CGSize(width: 720, height: 1280))
    }
    
    
    func onCapturedUnprocessedCVPixelBuffer(_ buffer: CVPixelBuffer, timestamp: CMTime, channel: ZegoPublishChannel) {
        self.beautifyService.effects.processImageBuffer(buffer)
        ZegoExpressEngine.shared().sendCustomVideoProcessedCVPixelBuffer(buffer, timestamp: timestamp, channel: channel)
    }
}
