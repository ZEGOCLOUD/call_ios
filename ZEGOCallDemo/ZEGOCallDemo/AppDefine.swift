//
//  AppDefine.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/28.
//

import UIKit

func ZGLocalizedString(_ key : String) -> String {
    return Bundle.main.localizedString(forKey: key, value: "", table: "Call")
}

func KeyWindow() -> UIWindow {
    let window: UIWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).last!
    return window
}
