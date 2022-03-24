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
    
    private typealias functionType = ([String : AnyObject], @escaping RequestCallback) -> ()
    
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
    private var callModel = FirebaseCallModel()
    
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
        functionsMap[API_Get_Users] = getUserList
        functionsMap[API_Start_Call] = callUsers
        functionsMap[API_Cancel_Call] = cancelCall
    }
}

extension FirebaseManager: RequestProtocol {
    func request(_ path: String, parameter: [String : AnyObject], callback: RequestCallback?) {
        print("[*] Firebase request: \(path),  parameter:\(parameter)")
        guard let function = functionsMap[path] else { return }
        
        var callback = callback
        if callback == nil {
            callback = { _ in }
        }
        function(parameter, callback!)
    }
}

// private functions
extension FirebaseManager {
     func login(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        
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
    
    private func logout(_ parameter: [String: AnyObject], callback: RequestCallback) {
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
    
    private func getUser(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        
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
    
    private func getUserList(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
                
        if user == nil {
            callback(.failure(.failed))
            return
        }
        
        let usersQuery = self.ref.child("online_user").queryOrdered(byChild: "last_changed")
        usersQuery.observeSingleEvent(of: .value) { snapshot in
            let userDicts: [[String : Any]] = snapshot.children.compactMap { child in
                return (child as? DataSnapshot)?.value as? [String : Any]
            }
            callback(.success(userDicts))
        }
    }
    
    private func callUsers(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        
        guard let callID = parameter["call_id"] as? String,
              let userID = parameter["id"] as? String,
              let callees = parameter["callees"] as? [String],
              let type = parameter["type"] as? Int
        else {
            callback(.failure(.failed))
            return
        }
        
        callModel.call_id = callID
        callModel.call_type = type
        callModel.call_status = 1
        callModel.users.removeAll()
        
        let startTime = Int(Date().timeIntervalSince1970 * 1000)
        let caller = FirebaseCallUser()
        caller.caller_id = userID
        caller.user_id = userID
        caller.start_time = startTime
        caller.status = 1
        callModel.users.append(caller)
        
        for callee_id in callees {
            let callee = caller.copy()
            callee.user_id = callee_id
            callModel.users.append(callee)
        }
        
        let callRef = ref.child("call/\(callID)")
        callRef.setValue(callModel.toDict()) { error, reference in
            if error == nil {
                callback(.success(()))
                self.addCallListener(callID)
            } else {
                callback(.failure(.failed))
            }
        }
    }
    
    private func cancelCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let userID = parameter["callee_id"] as? String,
              let callID = parameter["call_id"] as? String
        else {
            callback(.failure(.failed))
            return
        }
        
        let model = callModel.copy()
        model.call_status = 3
        
        if let caller = model.getUser(user?.uid) {
            caller.status = 5
        }
        if let callee = model.getUser(userID) {
            callee.status = 5
        }
        
        let callRef = ref.child("call/\(callID)")
//        callRef.updateChildValues(model.toDict()) { error, _ in
//            if error == nil {
//                callback(.success(()))
//                self.addCallListener(callID)
//            } else {
//                callback(.failure(.failed))
//            }
//        }
        callRef.setValue(model.toDict()) { error, _ in
            if error == nil {
                callback(.success(()))
                self.addCallListener(callID)
            } else {
                callback(.failure(.failed))
            }
        }
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
            let data: [String : Any?] = [
                "user_id" : user.uid,
                "display_name" : user.displayName,
                "token_id" : fcmToken,
                "last_changed" : Int(Date().timeIntervalSince1970 * 1000)
            ]
            let userRef = self.ref.child("online_user").child(user.uid)
            userRef.setValue(data)
            userRef.onDisconnectRemoveValue()
            
            
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
    
    private func addCallListener(_ callID: String) {
        let callRef = ref.child("call/\(callID)")
        callRef.observe(.childChanged) { snapshot in
            print(snapshot.value)
        }
    }
}
