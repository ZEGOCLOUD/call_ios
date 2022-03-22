//
//  CallTimeManager.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/22.
//

import UIKit

protocol CallTimeManagerDelegate: AnyObject {
    func onReceiceCallTimeUpdate(_ duration: Int)
}

class CallTimeManager: NSObject {
    
    let timer = ZegoTimer(1000)
    var startTime: Int = 0
    var callDuration: Int = 0
    weak var delegate: CallTimeManagerDelegate?
    
    func callStart() {
        startTime = Int(Date().timeIntervalSince1970)
        timer.setEventHandler {
            let currentTime = Int(Date().timeIntervalSince1970)
            self.callDuration = currentTime - self.startTime
            self.delegate?.onReceiceCallTimeUpdate(self.callDuration)
        }
        timer.start()
    }
    
    func callEnd() {
        startTime = 0
        callDuration = 0
        timer.stop()
    }
}
