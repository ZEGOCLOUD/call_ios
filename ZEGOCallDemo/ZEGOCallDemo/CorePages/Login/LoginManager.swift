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
                self?.heartBeatRequest()
            }
            self.timer.start()
            
            let token = AppToken.getZIMToken(withUserID: userID) ?? ""
            RoomManager.shared.userService.login(user, token, callback: callback)
            
        } failure: { requestStatus in
            guard let callback = callback else { return }
            let result: ZegoResult = .failure(.other(Int32(requestStatus?.code ?? -2)))
            callback(result)
        }
    }
    
    func logout() {
        timer.stop()
        RoomManager.shared.userService.logout()
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
    private func heartBeatRequest() {
        var request = HeartBeatRequest()
        request.userID = RoomManager.shared.userService.localUserInfo?.userID ?? ""
        RequestManager.shared.heartBeatRequest(request: request) { requestStatus in
        } failure: { requestStatus in
        }
    }
}