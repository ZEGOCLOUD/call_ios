//
//  DeviceService.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/27.
//

import UIKit
import ZegoExpressEngine

class DeviceService: NSObject {
    
    override init() {
        super.init()
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
    
    func enableSpeaker(_ enable: Bool) {
        ZegoExpressEngine.shared().setAudioRouteToSpeaker(enable)
    }

}
