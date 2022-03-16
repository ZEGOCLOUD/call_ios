//
//  SettingCellModel.swift
//  ZegoLiveAudioRoomDemo
//
//  Created by zego on 2021/12/14.
//

import UIKit

enum SettingCellType {
    case express
    case app
    case terms
    case privacy
    case shareLog
    case logout
}

class SettingCellModel: NSObject {
    
    var title : String?
    var subTitle : String?
    var type : SettingCellType = .express
}
