//
//  ZegoRoomManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZegoExpressEngine

/// Class ZEGOCall busainess logic management
///
/// Description: This class contains the ZEGOCall business logic, manages the service instances of different modules, and also distributing the data delivered by the SDK.
class ServiceManager: NSObject {
    
    /// Get the ServiceManager singleton instance
    ///
    /// Description: This method can be used to get the RoomManager singleton instance.
    ///
    /// Call this method at: Any time
    static let shared = ServiceManager()
    
    // MARK: - Private
    private let rtcEventDelegates: NSHashTable<ZegoEventHandler> = NSHashTable(options: .weakMemory)
    
    private override init() {
        userService = UserServiceImpl()
        callService = CallServiceImpl()
        deviceService = DeviceServiceImpl()
        roomService = RoomServiceImpl()
        streamService = StreamServiceImpl()
        super.init()
    }
    
    /// The user information management instance, contains the in-room user information management, logged-in user information and other business logic.
    open var userService: UserService
    
    /// The call information management instance, contains start, accept, and end call and other busuness logic.
    open var callService: CallService
    
    /// The device Information Management instance contains microphone, camera, and speaker infomation and other device Infomation.
    open var deviceService: DeviceService
    
    /// The stream Management instance contains play and publish stream logic.
    open var streamService: StreamService
    
    /// The room information Management instance contains join and leave room logic.
    var roomService: RoomService
    
    var isSDKInit: Bool = false
    
    /// Initialize the SDK
    ///
    /// Description: This method can be used to initialize the Express-Video SDK.
    ///
    /// Call this method at: Before you log in. We recommend you call this method when the application starts.
    ///
    /// - Parameter appID: refers to the project ID. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    /// - Parameter appSign: refers to the secret key for authentication. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    func initWithAppID(appID: UInt32, callback: ZegoCallback?) {
        
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.scenario = .communication
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)
        deviceService.setBestConfig()
        
        isSDKInit = true
        
        let initCommand = InitCommand()
        initCommand.execute(callback: nil)
        
        guard let callback = callback else { return }
        callback(.success(()))
    }
    
    
    /// The method to deinitialize the SDK
    ///
    /// Description: This method can be used to deinitialize the SDK and release the resources it occupies.
    ///
    /// Call this method at: When the SDK is no longer be used. We recommend you call this method when the application exits.
    func uninit() {
        isSDKInit = false
        ZegoExpressEngine.destroy(nil)
    }
    
    /// Upload local logs to the ZEGOCLOUD Server
    ///
    /// Description: You can call this method to upload the local logs to the ZEGOCLOUD Server for troubleshooting when exception occurs.
    ///
    /// Call this method at: When exceptions occur
    ///
    /// - Parameter callback: refers to the callback that be triggered when the logs are upload successfully or failed to upload logs.
    func uploadLog(callback: ZegoCallback?) {
        if isSDKInit == false {
            assert(false, "The SDK must be initialised first.")
            guard let callback = callback else { return }
            callback(.failure(.notInit))
            return
        }
        ZegoExpressEngine.shared().uploadLog { error in
            guard let callback = callback else { return }
            if error == 0 {
                callback(.success(()))
            } else {
                callback(.failure(.other(error)))
            }
        }
    }
}

extension ServiceManager {
    // MARK: - event handler
    func addExpressEventHandler(_ eventHandler: ZegoEventHandler?) {
        rtcEventDelegates.add(eventHandler)
    }
}

extension ServiceManager: ZegoEventHandler {
    
    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onRoomStateUpdate?(state, errorCode: errorCode, extendedData: extendedData, roomID: roomID)
        }
        assertErrorCode(errorCode)
    }
    
    func onRoomUserUpdate(_ updateType: ZegoUpdateType, userList: [ZegoUser], roomID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onRoomUserUpdate?(updateType, userList: userList, roomID: roomID)
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
        assertErrorCode(errorCode)
    }
    
    func onPublisherStateUpdate(_ state: ZegoPublisherState, errorCode: Int32, extendedData: [AnyHashable : Any]?, streamID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onPublisherStateUpdate?(state, errorCode: errorCode, extendedData: extendedData, streamID: streamID)
        }
        assertErrorCode(errorCode)
    }
    
    func onNetworkQuality(_ userID: String, upstreamQuality: ZegoStreamQualityLevel, downstreamQuality: ZegoStreamQualityLevel) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onNetworkQuality?(userID, upstreamQuality: upstreamQuality, downstreamQuality: downstreamQuality)
        }
    }
    
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onAudioRouteChange?(audioRoute)
        }
    }
    
    func onRemoteCameraStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onRemoteCameraStateUpdate?(state, streamID: streamID)
        }
    }
    
    func onRemoteMicStateUpdate(_ state: ZegoRemoteDeviceState, streamID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onRemoteMicStateUpdate?(state, streamID: streamID)
        }
    }
    
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onRoomTokenWillExpire?(remainTimeInSecond, roomID: roomID)
        }
    }
}
