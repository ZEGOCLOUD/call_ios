//
//  AppDefine.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/4/8.
//

import Foundation

func ZGAppLocalizedString(_ key: String) -> String {
    return ZGLocalizedString(key, tableName: "Localizable")
}
