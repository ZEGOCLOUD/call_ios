//
//  DeviceService.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

protocol DeviceServiceDelegate: AnyObject {
    
    /// Callback for the audio output route changed
    ///
    /// Description: this callback will be triggered when switching the audio output between speaker, receiver, and bluetooth headset.
    /// - Parameter audioRoute: the device type of audio output.
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
    
    /// Whether to enable or disable the video mirroring
    var videoMirror: Bool { get set}
    
    /// The device type of audio output
    var routeType: ZegoAudioRoute { get }
    
    /// The delegate instance of the device service.
    var delegate: DeviceServiceDelegate? { get set }
    
    func setDeviceDefaultConfig()
    
    /// Mutes or unmutes the microphone
    ///
    /// Description: This is used to control whether to use the collected audio data. Mute (turn off the microphone) will use the muted data to replace the audio data collected by the device for streaming. At this time, the microphone device will still be occupied.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param mute determines whether to mute (disable) the microphone, `true`: mute (disable) microphone, `false`: enable microphone.
    func enableMic(_ enable: Bool)
    
    /// Turns on/off the camera
    ///
    /// Description: This is used to control whether to start the camera acquisition. After the camera is turned off, video capture will not be performed. At this time, the publish stream will also have no video data.
    ///  Call this method at: After joining a room
    ///
    /// @param enable determines whether to turn on the camera, `true`: turn on camera, `false`: turn off camera.
    func enableCamera(_ enable: Bool)
    
    /// Use front-facing or rear camera
    ///
    /// Description: This can be used to set the camera, the SDK uses the front-facing camera by default.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param isFront determines whether to use the front-facing camera or the rear camera.  true: Use front-facing camera. false: Use rear camera.
    func useFrontCamera(_ isFront: Bool)
    
    /// Use speaker or receiver
    ///
    /// Description: This can be used to set the speaker and receiver.
    ///
    /// Call this method at: After joining a room
    ///
    /// @param enable determines whether to use the speaker or the receiver. true: use the speaker. false: use the receiver.
    func enableSpeaker(_ enable: Bool)
    
    
    /// Support/Not support for callkit
    ///
    /// Description: This can be used to set whether to support the callkit or not.
    ///
    /// @param enable determines whether to support the callkit. true: support. false: not supported.
    func enableCallKit(_ enable: Bool)
    
}
