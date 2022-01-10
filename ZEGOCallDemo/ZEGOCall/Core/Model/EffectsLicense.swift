//
//  EffectsLicense.swift
//  ZEGOLiveDemo
//
//  Created by Larry on 2021/12/30.
//

import UIKit
import ZegoEffects

class EffectsLicense: NSObject {
    var license = ""
    static let shared = EffectsLicense()
    private override init() {}
    
    func getLicense(_ appID: UInt32, appSign: String) {
        
        let encryptInfo = ZegoEffects.getAuthInfo(appSign)
        var request = EffectsLicenseRequest()
        request.appID = appID
        request.authInfo = encryptInfo
        RequestManager.shared.getEffectsLicense(request: request) { requestStatus in
            if let licenseString = requestStatus?.data["License"] as? String {
                self.license = licenseString
            }
        } failure: { requestStatus in
            
        }
    }
}
