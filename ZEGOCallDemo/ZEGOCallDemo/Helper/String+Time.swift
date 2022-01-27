//
//  String+Time.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation

extension String {
    
    static func getTimeFormate(_ time: Int) -> String {
        let allTime: Int = time
        var hours = 0
        var minutes = 0
        var seconds = 0
        var hoursText = ""
        var minutesText = ""
        var secondsText = ""
        
        hours = allTime / 3600
        hoursText = hours > 9 ? "\(hours)" : "0\(hours)"
        
        minutes = allTime % 3600 / 60
        minutesText = minutes > 9 ? "\(minutes)" : "0\(minutes)"
        
        seconds = allTime % 3600 % 60
        secondsText = seconds > 9 ? "\(seconds)" : "0\(seconds)"
        
        if hours > 0 {
            return "\(hoursText):\(minutesText):\(secondsText)"
        } else {
            return "\(minutesText):\(secondsText)"
        }
//        let str_minute = String(format: "%02ld", time / 60)
//        let str_second = String(format: "%02ld", time % 60)
//        let formateTime = String(format: "%@:%@", str_minute,str_second)
//        return formateTime
    }
    
}
