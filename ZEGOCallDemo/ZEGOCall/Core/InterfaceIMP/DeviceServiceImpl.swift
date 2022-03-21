//
//  DeviceServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

class DeviceServiceImpl: NSObject, DeviceService {
    
    var videoResolution: VideoResolution = .p720
    
    var bitrate: AudioBitrate = .b48
    
    var noiseSliming: Bool = false
    
    var echoCancellation: Bool = false
    
    var volumeAdjustment: Bool = false
    
    weak var delegate: DeviceServiceDelegate?
    
    override init() {
        super.init()
        // ServiceManager didn't finish init at this time.
        DispatchQueue.main.async {
            ServiceManager.shared.addExpressEventHandler(self)
        }
    }
    
    func enableNoiseSuppression(_ enable: Bool) {
        
    }
    
    func enableEchoCancellation(_ enable: Bool) {
        
    }
    
    func enableVolumeAdjustment(_ enable: Bool) {
        
    }
    
    func setVideoResolution(_ resolution: VideoResolution) {
        
    }
    
    func setAudioBitrate(_ bitrate: AudioBitrate) {
        
    }
    
    func enableMic(_ enable: Bool, callback: RoomCallback?) {
        
    }
    
    func enableCamera(_ enable: Bool, callback: RoomCallback?) {
        ZegoExpressEngine.shared().enableCamera(enable)
    }
    
    func useFrontCamera(_ isFront: Bool) {
        
    }
    
    func enableSpeaker(_ enable: Bool) {
        
    }
    
    func enableCallKit(_ enable: Bool) {
        
    }
}

extension DeviceServiceImpl: ZegoEventHandler {
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        
    }
}
