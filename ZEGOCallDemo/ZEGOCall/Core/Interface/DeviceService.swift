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
    
    var delegate: DeviceServiceDelegate? { get set }
    
    /// Configure device settings
    ///
    /// Description: This method can be used to configure device settings as actual business requirements.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param type refers to the configuration type.
    /// @param enable determines whether to enable or disable.
    func setDeviceStatus(_ type: DeviceType, enable: Bool)
    
    /// Set video resolution
    ///
    /// Description: This method can be used to set video resolution. A larger resolution consumes more network bandwidth. You can select the resolution based on service requirements and network conditions. The default value is 720P.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param resolution refers to the resolution value.
    func setVideoResolution(_ resolution: VideoResolution)
    
    /// Set audio bitrate
    ///
    /// Description: This method can be used to set audio bitrate.  A larger audio bitrate consumes more network bandwidth. You can select the bitrate based on service requirements and network conditions. The default value is 48kbps.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param bitrate refers to the bitrate value.
    func setAudioBitrate(_ bitrate: AudioBitrate)
    
    /// Microphone related operation
    ///
    /// Description: This method can be used to enable and disable the microphone. When the microphone is enabled, the SDK automatically publishes audio streams to remote users. When the microphone is disabled, the audio stream publishing stops automatically.
    ///
    /// Call this method at: After the call is connected
    ///
    /// - Parameter enable: indicates whether to enable or disable the microphone. true: Enable. false: Disable.
    /// - Parameter callback: refers to the callback for enable or disable the microphone.
    func enableMic(_ enable: Bool, callback: RoomCallback?)
    
    
    /// Camera related operation
    ///
    /// Description: This method can be used to enable and disable the camera. When the camera is enabled, the SDK automatically publishes video streams to remote users. When the camera is disabled, the video stream publishing stops automatically.
    ///
    /// Call this method at:  After the call is connected
    ///
    /// - Parameter enable: indicates whether to enable or disable the camera. true: Enable. false: Disable.
    /// - Parameter callback: refers to the callback for enable or disable the camera.
    func enableCamera(_ enable: Bool, callback: RoomCallback?)
    
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
    
    func startPlaying(_ userID: String?, streamView: UIView?)
    
    func stopPlaying(_ userID: String?)
}
