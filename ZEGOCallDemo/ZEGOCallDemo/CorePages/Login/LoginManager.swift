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
    
    func login(_ user: UserInfo, callback: loginCallBack?) {
        guard let userID = user.userID else {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        guard let userName = user.userName else {
            guard let callback = callback else { return }
            callback(.failure(.paramInvalid))
            return
        }
        
        var request = LoginRequest()
        request.userID = userID
        request.name = userName
        
        RequestManager.shared.loginRequest(request: request) { requestStatus in
            
            user.order = requestStatus?.data["order"] as? String ?? ""
            
            self.timer.setEventHandler { [weak self] in
                self?.heartBeatRequest(callback: { result in
                    if result.isFailure {
                        // try login
                        self?.tryReLogin(request: request)
                    }
                })
            }
            self.timer.start()
            
            //let token = AppToken.getZIMToken(withUserID: userID) ?? ""
            CallManager.shared.login(callback)
            
        } failure: { requestStatus in
            guard let callback = callback else { return }
            let result: ZegoResult = .failure(.other(Int32(requestStatus?.code ?? -2)))
            callback(result)
        }
    }
    
    func logout() {
        timer.stop()
        CallManager.shared.logout(nil)
    }
    
    func requestUserID(_ callback: UserIDCallBack?) {
        let request = UserIDReauest()
        RequestManager.shared.getUserIDRequest(request: request) { requestStatus in
            guard let callback = callback else { return }
            let userID: String = requestStatus?.data["id"] as? String ?? ""
            callback(.success(userID))
        } failure: { requestStatus in
            guard let callback = callback else { return }
            callback(.failure(.failed))
        }
    }
}

extension LoginManager {
    private func heartBeatRequest(callback: heartBeatCallBack?) {
        var request = HeartBeatRequest()
        request.userID =  CallManager.shared.localUserInfo?.userID ?? ""
        RequestManager.shared.heartBeatRequest(request: request) { requestStatus in
            guard let callback = callback else { return }
            var result: ZegoResult
            if requestStatus?.code == 0 {
                result = .success(())
            } else {
                result = .failure(.failed)
            }
            callback(result)
        } failure: { requestStatus in
            guard let callback = callback else { return }
            callback(.failure(.failed))
        }
    }
    
    private func tryReLogin(request:LoginRequest) {
        RequestManager.shared.loginRequest(request: request) { requestStatus in
            
        } failure: { requestStatus in
            // fail
        }
    }
}
