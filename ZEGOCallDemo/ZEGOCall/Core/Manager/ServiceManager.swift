//
//  ZegoRoomManager.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by Kael Ding on 2021/12/13.
//

import Foundation
import ZegoExpressEngine

/// Class ZEGOLive business logic management
///
/// Description: This class contains the ZEGOLive business logic, manages the service instances of different modules, and also distributing the data delivered by the SDK.
class ServiceManager: NSObject {
    
    /// Get the ZegoRoomManager singleton instance
    ///
    /// Description: This method can be used to get the RoomManager singleton instance.
    ///
    /// Call this method at: Any time
    static let shared = ServiceManager()
    
    // MARK: - Private
    private let rtcEventDelegates: NSHashTable<ZegoEventHandler> = NSHashTable(options: .weakMemory)
    
    private override init() {
        userService = UserServiceIMP()
        callService = CallServiceIMP()
        deviceService = DeviceServiceIMP()
        roomService = RoomServiceIMP()
        super.init()
    }
    
    /// The user information management instance, contains the in-room user information management, logged-in user information and other business logic.
    open var userService: UserService
    
    open var callService: CallService
    
    open var deviceService: DeviceService
    
    var roomService: RoomService
    
    /// Initialize the SDK
    ///
    /// Description: This method can be used to initialize the ZIM SDK and the Express-Audio SDK.
    ///
    /// Call this method at: Before you log in. We recommend you call this method when the application starts.
    ///
    /// - Parameter appID: refers to the project ID. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    /// - Parameter appSign: refers to the secret key for authentication. To get this, go to ZEGOCLOUD Admin Console: https://console.zego.im/dashboard?lang=en
    func initWithAppID(appID: UInt32, callback: RoomCallback?) {
        
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.scenario = .general
        ZegoExpressEngine.createEngine(with: profile, eventHandler: self)
        
        guard let callback = callback else { return }
        callback(.success(()))
    }
    
    
    /// The method to deinitialize the SDK
    ///
    /// Description: This method can be used to deinitialize the SDK and release the resources it occupies.
    ///
    /// Call this method at: When the SDK is no longer be used. We recommend you call this method when the application exits.
    func uninit() {
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
        guard let callback = callback else { return }
        ZegoExpressEngine.shared().uploadLog { error in
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
    
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        for delegate in rtcEventDelegates.allObjects {
            delegate.onAudioRouteChange?(audioRoute)
        }
    }
}
