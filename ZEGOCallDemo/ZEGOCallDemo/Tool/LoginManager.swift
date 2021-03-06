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

protocol LoginManagerDelegate: AnyObject {
    func onReceiveUserKickout()
}

class LoginManager {
    
    typealias loginCallback = (_ userID: String?, _ userName: String?, _ error: Int) -> Void
    
    static let shared = LoginManager()
    
    private var ref: DatabaseReference
    private var fcmToken: String?
    
    init() {
        ref = Database.database().reference()
        user = Auth.auth().currentUser
        
        if user != nil {
            UserListManager.shared.addOnlineUsersListener()
        }
        
        addConnectedListener()
    }
    
    var user: User? {
        willSet {
            if newValue?.uid != user?.uid && newValue != nil {
                addUserToDatabase(newValue!)
                UserListManager.shared.addOnlineUsersListener()
            } else if newValue == nil {
                UserListManager.shared.removeOnlineUsersListener()
            }
        }
    }
    
    weak var delegate: LoginManagerDelegate?
    
    func login(_ credential: AuthCredential, userName: String? = nil, callback: @escaping loginCallback) {
        
        Auth.auth().signIn(with: credential) { result, error in
            
            guard let user = result?.user else {
                callback(nil, nil, 1)
                return
            }
            self.user = user
            
            if user.displayName == nil && userName != nil {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = userName
                changeRequest?.commitChanges { error in
                    if error == nil {
                        self.user = nil
                        self.user = Auth.auth().currentUser
                    }
                }
            }
            
            callback(user.uid, user.displayName ?? userName ?? user.uid, 0)
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        resetData()
    }
}

extension LoginManager {
    
    private func resetData(_ removeUserData: Bool = true) {
        if let uid = user?.uid {
            let tokenRef = self.ref.child("online_user").child(uid).child("token_id")
            tokenRef.removeAllObservers()
            
            let userRef = self.ref.child("online_user").child(uid)
            userRef.cancelDisconnectOperations()
            if removeUserData {
                userRef.removeValue()
            }
        }
        user = nil
    }
    
    private func addConnectedListener() {
        ref.child(".info/connected").observe(.value) { snapshot in
            print("[* LoginManager] The User current connected state is \(String(describing: snapshot.value))")
            guard let connected = snapshot.value as? Bool, connected else { return }
            guard let user = self.user else { return }
            self.addUserToDatabase(user)
        }
    }
    
    private func addUserToDatabase(_ user: User) {
        
        func addUser(_ user: User, token: String?) {
            // setup database
            let data: [String : Any?] = [
                "user_id" : user.uid,
                "display_name" : user.displayName ?? user.uid,
                "token_id" : fcmToken,
                "last_changed" : Int(Date().timeIntervalSince1970 * 1000)
            ]
            let userRef = self.ref.child("online_user").child(user.uid)
            userRef.setValue(data) { error, reference in
                if error == nil {
                    print("[* LoginManager] Success to set user data to database.")
                } else {
                    print("[* LoginManager] Fail to set user data to database, error: \(error!)")
                }
            }
            userRef.onDisconnectRemoveValue()
            
            self.addFcmTokenListener(user.uid)
        }
        
        if fcmToken == nil {
            Messaging.messaging().token { token, error in
                guard let token = token else { return }
                self.fcmToken = token
                print("[* LoginManager] Success get fcm token: \(token)")
                addUser(user, token: self.fcmToken)
            }
        } else {
            addUser(user, token: self.fcmToken)
        }
    }
    
    private func addFcmTokenListener(_ userID: String) {
        let tokenRef = self.ref.child("online_user").child(userID).child("token_id")
        tokenRef.removeAllObservers()
        tokenRef.observe(.value) { snapshot in
            guard let token = snapshot.value as? String else { return }
            if token == self.fcmToken { return }
            print("[* LoginManager] Current User is logging at other device.")
            
            try? Auth.auth().signOut()
            self.resetData(false)
            CallManager.shared.resetCallData()
            self.delegate?.onReceiveUserKickout()
        }
    }
}
