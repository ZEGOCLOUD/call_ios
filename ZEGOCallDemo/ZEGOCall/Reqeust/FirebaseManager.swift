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
import FirebaseFunctions

class FirebaseManager: NSObject {
    
    private typealias functionType = ([String : AnyObject], @escaping RequestCallback) -> ()
    
    static let shared = FirebaseManager()
    weak var listener: ListenerUpdater? = ListenerManager.shared
    
    private var user: User? {
        willSet {
            if newValue?.uid != user?.uid && newValue != nil {
                addUserToDatabase(newValue!)
                addIncomingCallListener()
            }
        }
    }
    
    private var fcmToken: String?
    private var ref: DatabaseReference
    private var callModel: FirebaseCallModel?
    private var userDicts = [[String : Any]]()
    
    private var functionsMap = [String : functionType]()
    
    private override init() {
        Database.database().isPersistenceEnabled = true
        ref = Database.database().reference()
        super.init()
        
        addConnectedListener()
        
        Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
        }
        
        // add functions
        functionsMap[API_Start_Call] = callUsers
        functionsMap[API_Cancel_Call] = cancelCall
        functionsMap[API_Accept_Call] = acceptCall
        functionsMap[API_Decline_Call] = declineCall
        functionsMap[API_End_Call] = endCall
        functionsMap[API_Call_Heartbeat] = heartbeat
        functionsMap[API_Get_Token] = getToken
    }
    
    func resetData(_ removeUserData: Bool = true) {
        // remove all observers
        ref.child("online_user").removeAllObservers()
        ref.child("call").removeAllObservers()
        
        if let callID = callModel?.call_id {
            ref.child("call").child(callID).removeAllObservers()
        }
        
        if let uid = user?.uid {
            if let fcmToken = fcmToken {
                let fcmTokenRef = ref.child("push_token").child(uid).child(fcmToken)
                fcmTokenRef.removeValue()
                self.fcmToken = nil
            }
            
            let userRef = self.ref.child("online_user").child(uid)
            userRef.cancelDisconnectOperations()
            
            if removeUserData {
                userRef.removeValue()
            }
            self.user = nil
        }
        self.callModel = nil
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
    
    private func callUsers(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        
        guard let callID = parameter["call_id"] as? String,
              let userID = parameter["id"] as? String,
              let callees = parameter["callees"] as? [UserInfo],
              let typeOld = parameter["type"] as? Int,
              let type = FirebaseCallType.init(rawValue: typeOld)
        else {
            callback(.failure(.failed))
            return
        }
        callModel = FirebaseCallModel()
        guard let callModel = callModel else { return }
        
        callModel.call_id = callID
        callModel.call_type = type
        callModel.call_status = .connecting
        callModel.users.removeAll()
        
        let startTime = Int(Date().timeIntervalSince1970 * 1000)
        let caller = FirebaseCallUser()
        caller.caller_id = userID
        caller.user_id = userID
        caller.user_name = parameter["caller_name"] as? String
        caller.start_time = startTime
        caller.status = .connecting
        callModel.users.append(caller)
        
        for user in callees {
            let callee = caller.copy()
            callee.user_id = user.userID ?? ""
            callee.user_name = user.userName
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
        
        guard let model = callModel?.copy() else {
            callback(.failure(.failed))
            return
        }
        model.call_status = .ended
        
        if let caller = model.getUser(user?.uid) {
            caller.status = .canceled
        }
        if let callee = model.getUser(userID) {
            callee.status = .canceled
        }
        
        let callRef = ref.child("call/\(callID)")
        callRef.updateChildValues(model.toDict()) { error, _ in
            if error == nil {
                callback(.success(()))
                self.callModel = nil
            } else {
                callback(.failure(.failed))
            }
        }
    }
    
    private func acceptCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let callID = parameter["call_id"] as? String,
              let model = callModel
        else {
            callback(.failure(.failed))
            return
        }
        
        model.call_status = .calling;
        for user in model.users {
            user.status = .calling
            user.connected_time = Int(Date().timeIntervalSince1970 * 1000)
        }
        
        let callRef = ref.child("call").child(callID)
        callRef.updateChildValues(model.toDict()) { error, reference in
            if error == nil {
                callback(.success(()))
            } else {
                callback(.failure(.failed))
            }
        }
    }
    
    private func declineCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let callID = parameter["call_id"] as? String,
//              let callerID = parameter["caller_id"] as? String,
//              let userID = parameter["id"] as? String,
              let type = parameter["type"] as? DeclineType,
              let model = callModel
        else {
            callback(.failure(.failed))
            return
        }
        
        model.call_status = .ended
        for user in model.users {
            user.status = type == .decline ? .declined : .busy
        }
        
        let callRef = ref.child("call").child(callID)
        callRef.updateChildValues(model.toDict()) { error, reference in
            if error == nil {
                callback(.success(()))
                self.callModel = nil
            } else {
                callback(.failure(.failed))
            }
        }
    }
    
    private func endCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let callID = parameter["call_id"] as? String,
//              let userID = parameter["id"] as? String,
              let model = callModel
        else {
            callback(.failure(.failed))
            return
        }
        
        model.call_status = .ended
        for user in model.users {
            user.status = .ended
            user.finish_time = Int(Date().timeIntervalSince1970 * 1000)
        }
        
        let callRef = ref.child("call").child(callID)
        callRef.updateChildValues(model.toDict()) { error, reference in
            if error == nil {
                callback(.success(()))
                self.callModel = nil
            } else {
                callback(.failure(.failed))
            }
        }
    }
    
    private func heartbeat(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let userID = parameter["id"] as? String,
              let callID = parameter["call_id"] as? String,
              let callModel = callModel
        else {
            return
        }
        
        if callModel.call_status != .calling ||
            callModel.call_id != callID {
            return
        }
        
        guard let user = callModel.getUser(userID) else { return }
        
        let heartbeatTime = Int(Date().timeIntervalSince1970 * 1000)
        user.heartbeat_time = heartbeatTime
        
        let heartbeatRef = ref.child("call/\(callID)/users/\(userID)/heartbeat_time")
        heartbeatRef.setValue(ServerValue.timestamp())
    }
    
    private func getToken(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let userID = parameter["id"] as? String,
              let effectiveTimeInSeconds = parameter["effective_time"] as? Int
        else {
            callback(.failure(.failed))
            return
        }
        let functions = Functions.functions()
        let data: [String: Any] = [
            "id": userID,
            "effective_time": effectiveTimeInSeconds
        ]
        functions.httpsCallable("getToken").call(data) { result, error in
            if let error = error as NSError? {
                print("[*] Get token failed: \(error)")
                callback(.failure(.failed))
                return
            }
            guard let dict = result?.data as? [String: Any],
                  let token = dict["token"] as? String
            else {
                callback(.failure(.failed))
                return
            }
            let tokenData = ["token": token]
            callback(.success(tokenData))
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
            
            
            let fcmTokenRef = self.ref.child("push_token").child(user.uid).child(fcmToken ?? "")
            let tokenData: [String: Any?] = [
                "device_type" : "ios",
                "token_id": fcmToken,
                "user_id": user.uid
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
                        
            try? Auth.auth().signOut()
            self.resetData(false)
            
            let data = ["error" : 1]
            self.listener?.receiveUpdate(Notify_User_Error, parameter: data)
        }
    }
    
    // a incoming call will trigger this method
    private func addIncomingCallListener() {
        let callRef = ref.child("call")
        callRef.observe(.childAdded) { snapshot in
            guard let callDict = snapshot.value as? [String: Any] else {
                return
            }
            guard let callStatus = callDict["call_status"] as? Int,
                  callStatus == 1
            else {
                return
            }
            
            guard let model = FirebaseCallModel.model(with: callDict),
            let firebaseUser = model.getUser(self.user?.uid),
            firebaseUser.caller_id != firebaseUser.user_id else { return }
            
            guard let caller = model.users
                    .filter({ $0.caller_id == $0.user_id })
                    .first else { return }
            guard let startTime = caller.start_time else { return }
            let timeInterval = Int(Date().timeIntervalSince1970 * 1000) - startTime
            
            // if the start time of call is beyond 60s means this call is ended.
            if timeInterval > 60 * 1000 {
                return
            }
            
            if self.callModel == nil {
                self.callModel = model
                self.addCallListener(model.call_id)
            }
            let callees = model.users
                .filter({ $0.caller_id != $0.user_id })
                .compactMap({ UserInfo($0.user_id, $0.user_name ?? $0.user_id) })
            
            let data: [String: Any] = [
                "call_id": model.call_id,
                "call_type": model.call_type.rawValue,
                "caller_id": caller.caller_id,
                "caller_name": caller.user_name ?? caller.user_id,
                "callees": callees
            ]
            self.listener?.receiveUpdate(Notify_Call_Invited, parameter: data)
        }
    }
    
    private func addCallListener(_ callID: String) {
        let callRef = ref.child("call/\(callID)")
        callRef.observe(.value) { snapshot in
            
            guard let callDict = snapshot.value as? [String: Any],
                  let callStatus = callDict["call_status"] as? Int,
                  callStatus != 1
            else {
                return
            }
            
            guard let model = FirebaseCallModel.model(with: callDict),
                  let firebaseUser = model.getUser(self.user?.uid) else { return }
            
            // MARK: - callee receive call canceld
            if firebaseUser.user_id != firebaseUser.caller_id &&
                firebaseUser.status == .canceled &&
                self.callModel?.call_status == .connecting
            {
                let data: [String: Any] = [
                    "call_id": model.call_id,
                    "caller_id": firebaseUser.caller_id
                ]
                self.listener?.receiveUpdate(Notify_Call_Canceled, parameter: data)
                self.callModel = nil
            }
            
            // MARK: - caller receive call accept
            if firebaseUser.user_id == firebaseUser.caller_id &&
                firebaseUser.status == .calling &&
                self.callModel?.call_status == .connecting
            {
                guard let callee = model.users
                        .filter({ $0.user_id != firebaseUser.user_id })
                        .first else { return }
                let data: [String: Any] = [
                    "call_id": model.call_id,
                    "callee_id": callee.user_id
                ]
                self.listener?.receiveUpdate(Notify_Call_Accept, parameter: data)
                self.callModel = model
            }
            
            // MARK: - caller receive call decline
            if firebaseUser.user_id == firebaseUser.caller_id &&
                (firebaseUser.status == .declined || firebaseUser.status == .busy) &&
                self.callModel?.call_status == .connecting
            {
                guard let callee = model.users
                        .filter({ $0.user_id != firebaseUser.user_id })
                        .first else { return }
                if callee.status != .declined && callee.status != .busy { return }
                let type = callee.status == .declined ? 1 : 2
                let data: [String: Any] = [
                    "call_id": model.call_id,
                    "callee_id": callee.user_id,
                    "type": type
                ]
                self.listener?.receiveUpdate(Notify_Call_Decline, parameter: data)
                self.callModel = nil
            }
            
            // caller and callee receive call ended
            if model.call_status == .ended &&
                self.callModel?.call_status == .calling
            {
                guard let other = model.users
                        .filter({ $0.user_id != firebaseUser.user_id && $0.status == .ended })
                        .first else { return }
                let data: [String: Any] = [
                    "call_id": model.call_id,
                    "user_id": other.user_id
                ]
                self.listener?.receiveUpdate(Notify_Call_End, parameter: data)
                self.callModel = nil
            }
            
            // caller or callee receive connecting timeout
            if firebaseUser.status == .connectingTimeout &&
                self.callModel?.call_status == .connecting
            {
                
            }
            
            // caller or callee receive calling timeout
            if firebaseUser.status == .callingTimeout &&
                self.callModel?.call_status == .calling
            {
                
            }
        }
    }
}
