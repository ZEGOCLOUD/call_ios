//
//  DeviceService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

protocol DeviceServiceDelegate: AnyObject {
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute)
}

protocol DeviceService {
    
    /// Video resolution
    var videoResolution: VideoResolution { get set }
    
    /// Audio bitrate
    var bitrate: AudioBitrate { get set }
    
    /// Whether to enable or disable the noise suppression
    var noiseSliming: Bool { get set }
    
    /// Whether to enable or disable the echo cancellation
    var echoCancellation: Bool { get set }
    
    /// Whether to enable or disable the volume auto-adjustment
    var volumeAdjustment: Bool { get set }
    
    var videoMirror: Bool { get set}
    
    var routeType: ZegoAudioRoute { get }
    
    var delegate: DeviceServiceDelegate? { get set }
    
    
    func enableMic(_ enable: Bool)
    
    func enableCamera(_ enable: Bool)
    
    /// Use front-facing and rear camera
    ///
    /// Description: This method can be used to set the camera, the SDK uses the front-facing camera by default.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param isFront determines whether to use the front-facing camera or the rear camera.  true: Use front-facing camera. false: Use rear camera.
    func useFrontCamera(_ isFront: Bool)
    
    func enableSpeaker(_ enable: Bool)
    
    func enableCallKit(_ enable: Bool)
    
}
