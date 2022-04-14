//
//  DeviceServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

class DeviceServiceImpl: NSObject, DeviceService {
    
    var videoResolution: VideoResolution = .p720 {
        willSet {
            var expressVideoPreset: ZegoVideoConfigPreset = .preset720P
            switch newValue {
            case .p1080:
                expressVideoPreset = .preset1080P
            case .p720:
                expressVideoPreset = .preset720P
            case .p540:
                expressVideoPreset = .preset540P
            case .p360:
                expressVideoPreset = .preset360P
            case .p270:
                expressVideoPreset = .preset270P
            case .p180:
                expressVideoPreset = .preset180P
            }
            let videoConfig = ZegoVideoConfig.init(preset: expressVideoPreset)
            ZegoExpressEngine.shared().setVideoConfig(videoConfig)
        }
    }
    
    var bitrate: AudioBitrate = .b32 {
        willSet {
            let audioConfig = ZegoAudioConfig()
            audioConfig.codecID = .low3
            audioConfig.bitrate = 32
            switch newValue {
            case .b16: audioConfig.bitrate = 16
            case .b32
                : audioConfig.bitrate = 32
            case .b64: audioConfig.bitrate = 64
            case .b128: audioConfig.bitrate = 128
            }
            ZegoExpressEngine.shared().setAudioConfig(audioConfig)
        }
    }
    
    var noiseSliming: Bool = true {
        willSet {
            ZegoExpressEngine.shared().enableANS(newValue)
            ZegoExpressEngine.shared().enableTransientANS(newValue)
        }
    }
    
    var echoCancellation: Bool = true {
        willSet {
            ZegoExpressEngine.shared().enableAEC(newValue)
        }
    }
    
    var volumeAdjustment: Bool = true {
        willSet {
            ZegoExpressEngine.shared().enableAGC(newValue)
        }
    }
    
    var videoMirror: Bool = true {
        willSet {
            if videoMirror {
                ZegoExpressEngine.shared().setVideoMirrorMode(.bothMirror)
            } else {
                ZegoExpressEngine.shared().setVideoMirrorMode(.noMirror)
            }
        }
    }
    
    var routeType: ZegoAudioRoute {
        get {
            ZegoExpressEngine.shared().getAudioRouteType()
        }
    }
    
    weak var delegate: DeviceServiceDelegate?
    
    override init() {
        super.init()
        // ServiceManager didn't finish init at this time.
        DispatchQueue.main.async {
            ServiceManager.shared.addExpressEventHandler(self)
        }
    }
    
    func setBestConfig() {
        ZegoExpressEngine.shared().enableHardwareEncoder(true)
        ZegoExpressEngine.shared().enableHardwareDecoder(true)
        ZegoExpressEngine.shared().setCapturePipelineScaleMode(.post)
//        ZegoExpressEngine.shared().enableTrafficControl(true, property: .adaptiveResolution)
        ZegoExpressEngine.shared().setMinVideoBitrateForTrafficControl(120, mode: .ultraLowFPS)
        ZegoExpressEngine.shared().setTrafficControlFocusOn(.founsOnRemote)
        ZegoExpressEngine.shared().enableANS(false)
        let config = ZegoEngineConfig()
        config.advancedConfig = ["support_apple_callkit" : "true", "room_retry_time": "60"]
        ZegoExpressEngine.setEngineConfig(config)
    }
        
    func enableMic(_ enable: Bool) {
        ZegoExpressEngine.shared().muteMicrophone(!enable)
        ServiceManager.shared.userService.localUserInfo?.mic = enable
    }
    
    func enableCamera(_ enable: Bool) {
        ZegoExpressEngine.shared().enableCamera(enable)
        ServiceManager.shared.userService.localUserInfo?.camera = enable
    }
    
    func useFrontCamera(_ isFront: Bool) {
        ZegoExpressEngine.shared().useFrontCamera(isFront)
    }
    
    func enableSpeaker(_ enable: Bool) {
        ZegoExpressEngine.shared().setAudioRouteToSpeaker(enable)
    }
    
    func resetDeviceConfig() {
        videoResolution = .p720
        bitrate = .b32
        noiseSliming = true
        echoCancellation = true
        volumeAdjustment = true
        videoMirror = true
        ZegoExpressEngine.shared().enableCamera(true)
        ZegoExpressEngine.shared().muteMicrophone(false)
    }
}

extension DeviceServiceImpl: ZegoEventHandler {
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        delegate?.onAudioRouteChange(audioRoute)
    }
}
