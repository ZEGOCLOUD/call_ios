//
//  LoginManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/2/9.
//

import Foundation

class LoginManager: NSObject {
    typealias loginCallBack = (Result<Void, ZegoError>) -> Void
    typealias UserIDCallBack = (Result<String, ZegoError>) -> Void
    typealias heartBeatCallBack = (Result<Void, ZegoError>) -> Void
    
    static let shared = LoginManager()
    private var timer = ZegoTimer(15000)
    
    func logout() {
        timer.stop()
        CallManager.shared.logout()
    }
}

extension LoginManager {
    
}
