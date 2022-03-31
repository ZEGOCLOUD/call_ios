//
//  TokenManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/29.
//

import Foundation

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
    
    static let shared = TokenManager()
    
    init() {
        self.token = getTokenFromDisk()
    }
    
    var token: Token?

    
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
    
}
