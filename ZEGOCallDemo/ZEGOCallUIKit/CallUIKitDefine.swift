//
//  AppDefine.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/28.
//

import UIKit

func ZGLocalizedString(_ key : String, tableName: String) -> String {
    return Bundle.main.localizedString(forKey: key, value: "", table: tableName)
}

func ZGUIKitLocalizedString(_ key: String) -> String {
    return ZGLocalizedString(key, tableName: "Call")
}

func KeyWindow() -> UIWindow {
    let window: UIWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).last!
    return window
}

typealias TokenCallback = (String?) -> Void

let CALL_NOTI_START = "callStart"
let CALL_NOTI_END = "callEnd"
let CALL_NOTI_MUTE = "muteSpeaker"
