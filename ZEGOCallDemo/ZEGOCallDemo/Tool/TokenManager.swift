//
//  TokenManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/29.
//

import Foundation
import AVFoundation
import FirebaseFunctions

class Token {
    var token: String
    var expiryTime: Int
    
    init(_ token: String, expiryTime: Int) {
        self.token = token
        self.expiryTime = expiryTime
    }
    
    // 10 mins buffer
    func isTokenValid() -> Bool {
        return expiryTime > Int(Date().timeIntervalSince1970) + 10 * 60
    }
}

class TokenManager {
    
    typealias TokenCallback = (Result<String, ZegoError>) -> Void
    
    static let shared = TokenManager()
    
    private let tokenTimer = ZegoTimer(60 * 1000)
    
    init() {
        self.token = getTokenFromDisk()
        
        tokenTimer.setEventHandler {
            if self.needUpdateToken() {
                guard let userID = CallManager.shared.localUserInfo?.userID else { return }
                let effectiveTimeInSeconds = 24 * 3600
                self.getTokenFromServer(userID, effectiveTimeInSeconds) { result in
                    switch result {
                    case .success(let token):
                        self.saveToken(token, effectiveTimeInSeconds)
                        CallManager.shared.token = token
                    case .failure(_):
                        break
                    }
                }
            }
        }
        tokenTimer.start()
        
    }
    
    var token: Token?
    
    func getToken() {
        if token == nil {
            guard let userID = CallManager.shared.localUserInfo?.userID else { return }
            let effectiveTimeInSeconds = 24 * 3600
            self.getTokenFromServer(userID, effectiveTimeInSeconds) { result in
                switch result {
                case .success(let token):
                    self.saveToken(token, effectiveTimeInSeconds)
                    CallManager.shared.token = token
                case .failure(_):
                    HUDHelper.showMessage(message: ZGAppLocalizedString("token_get_fail"))
                }
            }
        } else {
            CallManager.shared.token = TokenManager.shared.token?.token
        }
    }

    
    func saveToken(_ token: String?, _ effectiveTimeInSeconds: Int) {
        
        let expiryTime: Int = Int(Date().timeIntervalSince1970) + effectiveTimeInSeconds
        
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "zego_token_key")
        defaults.set(expiryTime, forKey: "zego_token_expiry_time_key")
        
        guard let token = token else {
            self.token = nil
            return
        }
        self.token = Token(token, expiryTime: expiryTime)
    }
    
    func needUpdateToken() -> Bool {
        guard let token = token else {
            return true
        }
        // if the token invalid under 60mins, then we update the token.
        let current = Int(Date().timeIntervalSince1970)
        if current + 60 * 60 > token.expiryTime {
            return true
        }
        return false
    }
    
    private func getTokenFromDisk() -> Token? {
        
        let defaults = UserDefaults.standard
        
        guard let token = defaults.string(forKey: "zego_token_key")
        else {
            return nil
        }
        let expiryTime = defaults.integer(forKey: "zego_token_expiry_time_key")
        
        if expiryTime < Int(Date().timeIntervalSince1970) {
            return nil
        }
        
        return Token(token, expiryTime: expiryTime)
    }
    
    private func getTokenFromServer(_ userID: String,
                                    _ effectiveTimeInSeconds: Int,
                                    callback: @escaping TokenCallback) {
        
        let functions = Functions.functions()
        let data: [String: Any] = [
            "id": userID,
            "effective_time": effectiveTimeInSeconds
        ]
        functions.httpsCallable("getToken").call(data) { result, error in
            if let error = error as NSError? {
                print("[* Firebase] Get token failed: \(error)")
                callback(.failure(.networkError))
                return
            }
            guard let dict = result?.data as? [String: Any],
                  let token = dict["token"] as? String
            else {
                callback(.failure(.networkError))
                return
            }
            callback(.success(token))
        }
    }
    
}
