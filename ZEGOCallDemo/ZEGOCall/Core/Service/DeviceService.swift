//
//  DeviceService.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/6.
//

import UIKit
import ZegoExpressEngine


enum RTCVideoPreset: Int {
    case p1080
    case p720
    case p540
    case p360
    case p270
    case p180
}

enum RTCAudioBitrate: Int {
    case b16
    case b48
    case b56
    case b128
    case b192
}

enum RTCVideoCode: Int {
    case h264
    case h265
}

class DeviceService: NSObject {

    var videoPreset: RTCVideoPreset = .p720
    var audioBitrate: RTCAudioBitrate = .b48
    var videoCodeID: RTCVideoCode = .h264
    var layerCoding: Bool = false
    var hardwareCoding: Bool = true
    var hardwareDecoding: Bool = false
    var noiseRedution: Bool = false
    var echo: Bool = false
    var micVolume: Bool = false
    
    override init() {
        super.init()
        setNomalConfigValue()
    }
    
    
    func setVideoPreset(_ preset: RTCVideoPreset) {
        videoPreset = preset
        var expressVideoPreset: ZegoVideoConfigPreset = .preset720P
        switch preset {
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
        let videoConfig: ZegoVideoConfig = ZegoVideoConfig.init(preset: expressVideoPreset)
        switch videoCodeID {
        case .h264:
            if layerCoding {
                videoConfig.codecID = .IDSVC
            } else {
                videoConfig.codecID = .idDefault
            }
        case .h265:
            videoConfig.codecID = .IDH265
        }
        ZegoExpressEngine.shared().setVideoConfig(videoConfig)
    }
    
    func setAudioBitrate(_ bitrate: RTCAudioBitrate) {
        audioBitrate = bitrate
        var expressAudioPreset: ZegoAudioConfigPreset = .standardQuality
        switch bitrate {
        case .b16:
            expressAudioPreset = .basicQuality
        case .b48:
            expressAudioPreset = .standardQuality
        case .b56:
            expressAudioPreset = .standardQualityStereo
        case .b128:
            expressAudioPreset = .highQuality
        case .b192:
            expressAudioPreset = .highQualityStereo
        }
        let audioConfig: ZegoAudioConfig = ZegoAudioConfig.init(preset: expressAudioPreset)
        ZegoExpressEngine.shared().setAudioConfig(audioConfig)
    }
    
    func setVideoCodeID(_ ID: RTCVideoCode) {
        videoCodeID = ID
        var expressCodeID: ZegoVideoCodecID = .idDefault
        switch ID {
        case .h264:
            if layerCoding {
                expressCodeID = .IDSVC
            } else {
                expressCodeID = .idDefault
            }
            setLiveDeviceStatus(.hardware, enable: true)
        case .h265:
            if !ZegoExpressEngine.shared().isVideoEncoderSupported(.IDH265) {
                expressCodeID = .idDefault
            } else {
                expressCodeID = .IDH265
                setLiveDeviceStatus(.hardware, enable: true)
            }
        }
    }
    
    func setLiveDeviceStatus(_ statusType: SettingSelectionType, enable: Bool) {
        switch statusType {
        case .encoding, .resolution, .bitrate:
            return
        case .layered:
            layerCoding = enable
        case .hardware:
            ZegoExpressEngine.shared().enableHardwareEncoder(enable)
            hardwareCoding = enable
        case .decoding:
            ZegoExpressEngine.shared().enableHardwareDecoder(enable)
            hardwareDecoding = enable
        case .noise:
            noiseRedution = enable
            ZegoExpressEngine.shared().enableANS(enable)
            ZegoExpressEngine.shared().enableTransientANS(enable)
        case .echo:
            echo = enable
            ZegoExpressEngine.shared().enableAEC(enable)
        case .volume:
            micVolume = enable
            ZegoExpressEngine.shared().enableAGC(enable)
        }
    }
    
    func enableCamera(_ enable: Bool) {
        ZegoExpressEngine.shared().enableCamera(enable)
    }
    
    func muteMicrophone(_ mute: Bool) {
        ZegoExpressEngine.shared().muteMicrophone(mute)
    }
    
    func useFrontCamera(_ enable: Bool) {
        ZegoExpressEngine.shared().useFrontCamera(enable)
    }
    
    func setNomalConfigValue() {
        setVideoCodeID(videoCodeID)
        setVideoPreset(videoPreset)
        setAudioBitrate(audioBitrate)
        setLiveDeviceStatus(.layered, enable: layerCoding)
        setLiveDeviceStatus(.hardware, enable: hardwareCoding)
        setLiveDeviceStatus(.decoding, enable: hardwareDecoding)
        setLiveDeviceStatus(.noise, enable: noiseRedution)
        setLiveDeviceStatus(.echo, enable: echo)
        setLiveDeviceStatus(.volume, enable: micVolume)
    }
    
    func resert() {
        videoPreset = .p720
        audioBitrate = .b48
        videoCodeID = .h264
        layerCoding = false
        hardwareCoding = true
        hardwareDecoding = false
        noiseRedution = false
        echo = false
        micVolume = false
        setNomalConfigValue()
    }
    
}
