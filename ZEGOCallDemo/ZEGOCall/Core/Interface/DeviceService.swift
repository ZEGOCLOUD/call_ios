//
//  DeviceService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

protocol DeviceServiceDelegate: AnyObject {
    
    /// Callback for the audio route
    ///
    /// Description: Callback for the audio route, and this callback will be triggered after the audio receiving device is switched
    /// - Parameter audioRoute: Refers to the user ID of the stream publisher or stream subscriber.
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
    
    /// Whether to enable or disable video mirroring
    var videoMirror: Bool { get set}
    
    /// Audio route
    var routeType: ZegoAudioRoute { get }
    
    /// device service delegate
    var delegate: DeviceServiceDelegate? { get set }
    
    /// Mutes or unmutes the microphone.
    ///
    /// Description: This function is used to control whether to use the collected audio data. Mute (turn off the microphone) will use the muted data to replace the audio data collected by the device for streaming. At this time, the microphone device will still be occupied.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param mute Whether to mute (disable) the microphone, `true`: mute (disable) microphone, `false`: enable microphone.
    func enableMic(_ enable: Bool)
    
    /// Turns on/off the camera.
    ///
    /// Description: This function is used to control whether to start the camera acquisition. After the camera is turned off, video capture will not be performed. At this time, the publish stream will also have no video data.
    ///  Call this method at: After joining a room
    ///
    /// @param enable Whether to turn on the camera, `true`: turn on camera, `false`: turn off camera
    func enableCamera(_ enable: Bool)
    
    /// Use front-facing and rear camera
    ///
    /// Description: This method can be used to set the camera, the SDK uses the front-facing camera by default.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param isFront determines whether to use the front-facing camera or the rear camera.  true: Use front-facing camera. false: Use rear camera.
    func useFrontCamera(_ isFront: Bool)
    
    /// Use speakers and earphones
    ///
    /// Description: This method can be used to set the speakers/earphones, the SDK uses the earphones by default.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param enable determines whether to use a speaker or handset. true: Use the speakers. false: Use the earphones.
    func enableSpeaker(_ enable: Bool)
    
    
    /// Whether callKit is supported or not
    ///
    /// Description: This method can be used to set the whether callKit is supported, the SDK uses the callkit by default.
    ///
    /// @param enable determines whether callKit is supported. true: support callkit. false: not support callkit.
    func enableCallKit(_ enable: Bool)
    
}
