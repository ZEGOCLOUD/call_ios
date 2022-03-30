//
//  FirebaseTool.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/30.
//

import Foundation
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging
import FirebaseFunctions

class LoginManager {
    
    typealias loginCallback = (_ user: UserInfo?, _ error: Int) -> Void
    
    static let shared = LoginManager()
    
    var user: UserInfo?
    
    func login(_ token: String, callback: @escaping loginCallback) {
        
        let credential = GoogleAuthProvider.credential(withIDToken: token,
                                                       accessToken: "")
        Auth.auth().signIn(with: credential) { result, error in
            
            guard let user = result?.user else {
                callback(nil, 1)
                return
            }
            self.user = UserInfo(userID: user.uid, userName: user.displayName ?? user.uid)
            callback(self.user, 0)
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
    }
    
    func isUserLogin() -> Bool {
        guard let user = Auth.auth().currentUser else {
            return false
        }
        self.user = UserInfo(user.uid, user.displayName ?? user.uid)
        return true
    }
}
