//
//  String+Time.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation

extension String {
    
    static func getTimeFormate(_ time: Int) -> String {
        
        let str_minute = String(format: "%02ld", time / 60)
        let str_second = String(format: "%02ld", time % 60)
        let formateTime = String(format: "%@:%@", str_minute,str_second)
        return formateTime
    }
    
}
