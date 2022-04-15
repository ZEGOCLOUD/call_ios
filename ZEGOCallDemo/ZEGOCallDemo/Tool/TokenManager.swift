//
//  TokenManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/29.
//

import Foundation
import FirebaseFunctions

class Token {
    var token: String
    var expiryTime: Int
    var userID: String
    
    init(_ token: String, expiryTime: Int, userID: String) {
        self.token = token
        self.expiryTime = expiryTime
        self.userID = userID
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
            guard let userID = self.token?.userID else { return }
            if self.needUpdateToken(userID) {
                self.updateToken(userID, callback: nil)
            }
        }
        tokenTimer.start()
        
    }
    
    private var token: Token?
    
    func getToken(_ userID: String, callback: @escaping TokenCallback) {
        
        if needUpdateToken(userID) {
            updateToken(userID) { result in
                switch result {
                case .success(let token):
                    callback(.success(token))
                case .failure(_):
                    callback(.failure(.failed))
                }
            }
        } else {
            guard let token = token else {
                callback(.failure(.failed))
                return
            }
            callback(.success(token.token))
        }
    }

    
    func saveToken(_ userID: String, token: String?, _ effectiveTimeInSeconds: Int) {
        
        let expiryTime: Int = Int(Date().timeIntervalSince1970) + effectiveTimeInSeconds
        
        let defaults = UserDefaults.standard
        defaults.set(token, forKey: "zego_token_key")
        defaults.set(expiryTime, forKey: "zego_token_expiry_time_key")
        defaults.set(userID, forKey: "zego_user_id_key")
        
        guard let token = token else {
            self.token = nil
            return
        }
        self.token = Token(token, expiryTime: expiryTime, userID: userID)
    }
    
    func needUpdateToken(_ userID: String) -> Bool {
        guard let token = token else {
            return true
        }
        if token.userID != userID {
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
        
        guard let userID = CallManager.shared.localUserInfo?.userID else {
            return nil
        }
        
        let oldUserID = defaults.string(forKey: "zego_user_id_key")
        
        if oldUserID != userID {
            return nil
        }
        
        return Token(token, expiryTime: expiryTime, userID: userID)
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
    
    private func updateToken(_ userID: String, callback: TokenCallback?) {
        let effectiveTimeInSeconds = 24 * 3600
        self.getTokenFromServer(userID, effectiveTimeInSeconds) { result in
            switch result {
            case .success(let token):
                self.saveToken(userID, token: token, effectiveTimeInSeconds)
                guard let callback = callback else { return }
                callback(.success(token))
            case .failure(let error):
                guard let callback = callback else { return }
                callback(.failure(error))
            }
        }
    }
    
}
