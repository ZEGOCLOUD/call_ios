//
//  CallManager+CallTime.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/22.
//

import Foundation

extension CallManager: CallTimeManagerDelegate {
    
    func onReceiceCallTimeUpdate(_ duration: Int) {
        updateDisplayTime(duration)
    }
    
    func updateDisplayTime(_ duration: Int) {
        currentCallVC?.updateCallTimeDuration(duration)
        minmizedManager.updateCallTimeText(String.getTimeFormate(duration))
    }
}
