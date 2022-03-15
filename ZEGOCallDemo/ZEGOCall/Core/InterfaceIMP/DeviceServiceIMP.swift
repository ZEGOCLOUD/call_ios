//
//  DeviceServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

class DeviceServiceIMP: NSObject, DeviceService {
    
    var videoResolution: ZegoVideoResolution = .p720
    
    var bitrate: ZegoAudioBitrate = .b48
    
    var noiseSliming: Bool = false
    
    var echoCancellation: Bool = false
    
    var volumeAdjustment: Bool = false
    
    func setDeviceStatus(_ type: ZegoDeviceType, enable: Bool) {
        
    }
    
    func setVideoResolution(_ resolution: ZegoVideoResolution) {
        
    }
    
    func setAudioBitrate(_ bitrate: ZegoAudioBitrate) {
        
    }
    
    func enableMic(_ enable: Bool, callback: RoomCallback?) {
        
    }
    
    func enableCamera(_ enable: Bool, callback: RoomCallback?) {
        
    }
    
    func useFrontCamera(_ isFront: Bool) {
        
    }
    
    func enableSpeaker(_ enable: Bool) {
        
    }
    
    func enableCallKit(_ enable: Bool) {
        
    }
    
    func startPlaying(_ userID: String?, streamView: UIView?) {
        guard let roomID = ServiceManager.shared.roomService.roomInfo?.roomID else { return }
        let streamID = String.getStreamID(userID, roomID: roomID)
        if streamView != nil {
            guard let streamView = streamView else { return }
            let canvas = ZegoCanvas(view: streamView)
            canvas.viewMode = .aspectFill
            if ServiceManager.shared.userService.localUserInfo?.userID == userID {
                ZegoExpressEngine.shared().startPreview(canvas)
            } else {
                ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
            }
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
        }
    }
    
    func stopPlaying(_ userID: String?) {
        
    }
    
    
}
