//
//  FirebaseManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging

class FirebaseManager: NSObject {
    
    private typealias functionType = ([String : AnyObject], RequestCallback?) -> ()
    
    static let shared = FirebaseManager()
    weak var listener: ListenerUpdater? = ListenerManager.shared
    
    private var user: User? {
        willSet {
            if newValue?.uid != user?.uid && newValue != nil {
                addUserToDatabase(newValue!)
            }
        }
    }
    
    private var fcmToken: String?
    private var ref: DatabaseReference
    
    private var functionsMap = [String : functionType]()
    
    private override init() {
        Database.database().isPersistenceEnabled = true
        ref = Database.database().reference()
        super.init()
        
        addConnectedListener()
        
        // add functions
        functionsMap[API_GetUser] = getUser
        functionsMap[API_Login] = login
        functionsMap[API_Logout] = logout
    }
}

extension FirebaseManager: RequestProtocol {
    func request(_ path: String, parameter: [String : AnyObject], callback: RequestCallback?) {
        print("[*] Firebase request: \(path),  parameter:\(parameter)")
        guard let function = functionsMap[path] else { return }
        function(parameter, callback)
    }
}

// private functions
extension FirebaseManager {
    private func login(_ parameter: [String: AnyObject], callback: RequestCallback?) {
        guard let callback = callback else { return }
        
        guard let token = parameter["token"] as? String else {
            callback(.failure(.paramInvalid))
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: token,
                                                       accessToken: "")
        Auth.auth().signIn(with: credential) { result, error in
            guard let user = result?.user else {
                callback(.failure(.failed))
                return
            }
            self.user = user
            
            var result = [String : String]()
            result["id"] = user.uid
            result["name"] = user.displayName
            callback(.success(result))
        }
    }
    
    private func logout(_ parameter: [String: AnyObject], callback: RequestCallback?) {
        do {
            try Auth.auth().signOut()
            let fcmTokenRef = self.ref.child("push_token").child(fcmToken ?? "")
            fcmTokenRef.removeValue()
            
            if let uid = user?.uid {
                let userRef = self.ref.child("online_user").child(uid)
                userRef.removeValue()
                self.user = nil
            }
        } catch {
            
        }
    }
    
    private func getUser(_ parameter: [String: AnyObject], callback: RequestCallback?) {
        guard let callback = callback else { return }
        
        let auth = Auth.auth()
        guard let currentUser = auth.currentUser else {
            callback(.failure(.failed))
            return
        }
        self.user = auth.currentUser
        
        var result = [String : String]()
        result["id"] = currentUser.uid
        result["name"] = currentUser.displayName
        callback(.success(result))
    }
}


// notify
extension FirebaseManager {
    private func addConnectedListener() {
        ref.child(".info/connected").observe(.value) { snapshot in
            guard let connected = snapshot.value as? Bool, connected else { return }
            guard let user = self.user else { return }
            self.addUserToDatabase(user)
        }
    }
    private func addUserToDatabase(_ user: User) {
        
        func addUser(_ user: User, token: String?) {
            // setup database
            let data = [
                "user_id" : user.uid,
                "display_name" : user.displayName,
                "token_id" : fcmToken
            ]
            let userRef = self.ref.child("online_user").child(user.uid)
            userRef.setValue(data)
            userRef.onDisconnectRemoveValue()
            
            let lastChangeRef = self.ref.child("online_user").child(user.uid).child("last_changed")
            lastChangeRef.setValue(ServerValue.timestamp())
            
            let fcmTokenRef = self.ref.child("push_token").child(fcmToken ?? "")
            let tokenData = [
                "token_id" : fcmToken,
                "user_id" : user.uid,
                "device_type" : "ios"
            ]
            fcmTokenRef.setValue(tokenData)
        }
        
        if fcmToken == nil {
            Messaging.messaging().token { token, error in
                guard let token = token else { return }
                self.fcmToken = token
                addUser(user, token: self.fcmToken)
                self.addFcmTokenListener()
            }
        } else {
            addUser(user, token: self.fcmToken)
        }
    }
    
    private func addFcmTokenListener() {
        guard let uid = user?.uid else { return }
        let tokenRef = self.ref.child("online_user").child(uid).child("token_id")
        tokenRef.observe(.value) { snapshot in
            guard let token = snapshot.value as? String else { return }
            if token == self.fcmToken { return }
            print("[*] Current User is logging at other device.")
            let data = ["error" : 1]
            self.listener?.receiveUpdate(Notify_User_Error, parameter: data)
        }
    }
}
