//
//  LiveSettingSecondLevelModel.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/6.
//

import UIKit

class CallSettingSecondLevelModel: NSObject {
    
    var title: String?
    var type: Int = 0
    var isSelected: Bool = false

    init(json: Dictionary<String, Any>) {
        if let title = json["title"] as? String {
            self.title = title
        }
        if let type = json["type"] as? Int {
            self.type = type
        }
        if let isSelected = json["isSelected"] as? Bool {
            self.isSelected = isSelected
        }
    }
}
