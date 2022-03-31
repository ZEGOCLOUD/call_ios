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

class LoginManager {
    
    typealias loginCallback = (_ user: UserInfo?, _ error: Int) -> Void
    
    static let shared = LoginManager()
    
    private var _user: UserInfo? {
        willSet {
            if newValue?.userID != _user?.userID && newValue != nil {
                UserListManager.shared.addOnlineUsersListener()
            } else if newValue == nil {
                UserListManager.shared.removeOnlineUsersListener()
            }
        }
    }
    var user: UserInfo? {
        get {
            if _user != nil {
                return _user
            } else {
                guard let firebaseUser = Auth.auth().currentUser else { return nil }
                _user = UserInfo(firebaseUser.uid, firebaseUser.displayName ?? firebaseUser.uid)
                return _user
            }
        }
    }
    
    func login(_ token: String, callback: @escaping loginCallback) {
        
        let credential = GoogleAuthProvider.credential(withIDToken: token,
                                                       accessToken: "")
        Auth.auth().signIn(with: credential) { result, error in
            
            guard let user = result?.user else {
                callback(nil, 1)
                return
            }
            self._user = UserInfo(userID: user.uid, userName: user.displayName ?? user.uid)
            callback(self.user, 0)
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        _user = nil
    }
}
