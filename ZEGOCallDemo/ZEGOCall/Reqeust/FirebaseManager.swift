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
                addFcmTokenToDatabase()
                addIncomingCallListener()
            } else if newValue == nil {
                resetData()
            }
        }
    }
    
    private var fcmToken: String?
    private var ref: DatabaseReference
    private var modelDict = [String: FirebaseCallModel]()
    private var userDicts = [[String : Any]]()
    
    private var functionsMap = [String : functionType]()
    
    private override init() {
        ref = Database.database().reference()
        super.init()
        
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
    }
    
    func resetData() {
        // remove all observers
        ref.child("call").removeAllObservers()
        
        for callID in modelDict.keys {
            ref.child("call").child(callID).removeAllObservers()
        }
        
        if let uid = user?.uid {
            if let fcmToken = fcmToken {
                let fcmTokenRef = ref.child("push_token").child(uid).child(fcmToken)
                fcmTokenRef.removeValue()
                self.fcmToken = nil
            }
        }
        modelDict.removeAll()
    }
}

extension FirebaseManager: RequestProtocol {
    func request(_ path: String, parameter: [String : AnyObject], callback: RequestCallback?) {
        print("[* Firebase] Firebase request: \(path),  parameter:\(parameter)")
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
              let caller = parameter["caller"] as? UserInfo,
              let callees = parameter["callees"] as? [UserInfo],
              let typeOld = parameter["type"] as? Int,
              let type = FirebaseCallType.init(rawValue: typeOld)
        else {
            callback(.failure(.paramInvalid))
            return
        }
        let callModel = FirebaseCallModel()
        
        callModel.call_id = callID
        callModel.call_type = type
        callModel.call_status = .connecting
        callModel.users.removeAll()
        
        let startTime = Int(Date().timeIntervalSince1970 * 1000)
        let firebaseCaller = FirebaseCallUser()
        firebaseCaller.caller_id = caller.userID ?? ""
        firebaseCaller.user_id = caller.userID ?? ""
        firebaseCaller.user_name = caller.userName
        firebaseCaller.start_time = startTime
        firebaseCaller.status = .connecting
        callModel.users.append(firebaseCaller)
        
        for user in callees {
            let callee = firebaseCaller.copy()
            callee.user_id = user.userID ?? ""
            callee.user_name = user.userName
            callModel.users.append(callee)
        }
        
        let callRef = ref.child("call/\(callID)")
        callRef.setValue(callModel.toDict()) { error, reference in
            if error == nil {
                callback(.success(()))
                self.modelDict[callID] = callModel
                self.addCallListener(callID)
            } else {
                callback(.failure(.networkError))
            }
        }
    }
    
    private func cancelCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let calleeID = parameter["callee_id"] as? String,
              let callID = parameter["call_id"] as? String,
              let userID = parameter["id"] as? String
        else {
            callback(.failure(.paramInvalid))
            return
        }
        
        guard let model = modelDict[callID]?.copy() else {
            callback(.failure(.failed))
            return
        }
        model.call_status = .ended
        
        if let caller = model.getUser(userID) {
            caller.status = .canceled
        }
        if let callee = model.getUser(calleeID) {
            callee.status = .canceled
        }
        
        let callRef = ref.child("call/\(callID)")
        callRef.runTransactionBlock { currentData in
            guard let _ = currentData.value as? [String: Any] else {
                return .abort()
            }
            currentData.value = model.toDict()
            return .success(withValue: currentData)
        } andCompletionBlock: { error, bool, snapshot in
            if error == nil {
                callback(.success(()))
                self.modelDict.removeValue(forKey: callID)
            } else {
                callback(.failure(.networkError))
            }
        }
    }
    
    private func acceptCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let callID = parameter["call_id"] as? String,
              let model = modelDict[callID]
        else {
            callback(.failure(.paramInvalid))
            return
        }
        
        model.call_status = .calling;
        for user in model.users {
            user.status = .calling
            user.connected_time = Int(Date().timeIntervalSince1970 * 1000)
        }
        
        let callRef = ref.child("call").child(callID)
        callRef.runTransactionBlock { currentData in
            guard let _ = currentData.value as? [String: Any] else {
                return .abort()
            }
            currentData.value = model.toDict()
            return .success(withValue: currentData)
        } andCompletionBlock: { error, bool, snapshot in
            if error == nil {
                callback(.success(()))
            } else {
                callback(.failure(.networkError))
            }
        }
    }
    
    private func declineCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let callID = parameter["call_id"] as? String,
//              let callerID = parameter["caller_id"] as? String,
//              let userID = parameter["id"] as? String,
              let type = parameter["type"] as? DeclineType
        else {
            callback(.failure(.paramInvalid))
            return
        }
        
        let callRef = ref.child("call").child(callID)
        
        callRef.runTransactionBlock { currentData in
            guard let data = currentData.value as? [String: Any] else {
                return .abort()
            }
            guard let model = FirebaseCallModel.model(with: data) else {
                return .abort()
            }
            model.call_status = .ended
            for user in model.users {
                user.status = type == .decline ? .declined : .busy
            }
            currentData.value = model.toDict()
            return .success(withValue: currentData)
        } andCompletionBlock: { error, flag, snapshot in
            if error == nil {
                callback(.success(()))
                self.modelDict.removeValue(forKey: callID)
            } else {
                callback(.failure(.networkError))
            }
        }

    }
    
    private func endCall(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let callID = parameter["call_id"] as? String,
//              let userID = parameter["id"] as? String,
              let model = modelDict[callID]
        else {
            callback(.failure(.paramInvalid))
            return
        }
        
        model.call_status = .ended
        for user in model.users {
            user.status = .ended
            user.finish_time = Int(Date().timeIntervalSince1970 * 1000)
        }
        
        let callRef = ref.child("call").child(callID)
        callRef.runTransactionBlock { currentData in
            guard let _ = currentData.value as? [String: Any] else {
                return .abort()
            }
            currentData.value = model.toDict()
            return .success(withValue: currentData)
        } andCompletionBlock: { error, bool, snapshot in
            if error == nil {
                callback(.success(()))
                self.modelDict.removeValue(forKey: callID)
            } else {
                callback(.failure(.networkError))
            }
        }
    }
    
    private func heartbeat(_ parameter: [String: AnyObject], callback: @escaping RequestCallback) {
        guard let userID = parameter["id"] as? String,
              let callID = parameter["call_id"] as? String,
              let callModel = modelDict[callID]
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
}


// notify
extension FirebaseManager {
    private func addFcmTokenToDatabase() {
        
        func addFcmToken(token: String?) {
            guard let uid = user?.uid else { return }
            guard let token = token else { return }
            
            let tokenData: [String: Any?] = [token: [
                                                    "device_type" : "ios",
                                                    "token_id": token,
                                                    "user_id": uid]
                                            ]
            ref.child("push_token").child(uid).setValue(tokenData)
        }
        
        if fcmToken == nil {
            Messaging.messaging().token { token, error in
                guard let token = token else { return }
                self.fcmToken = token
                addFcmToken(token: token)
            }
        } else {
            addFcmToken(token: fcmToken)
        }
    }
    
    // a incoming call will trigger this method
    private func addIncomingCallListener() {
        let callRef = ref.child("call")
        callRef.removeAllObservers()
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
            
            if self.modelDict[model.call_id] == nil {
                self.modelDict[model.call_id] = model
                self.addCallListener(model.call_id)
            }
            
            let callees = model.users
                .filter({ $0.caller_id != $0.user_id })
                .compactMap({ UserInfo($0.user_id, $0.user_name ?? $0.user_id) })
            let callerUser = UserInfo(caller.user_id, caller.user_name ?? caller.user_id)
            let data: [String: Any] = [
                "call_id": model.call_id,
                "call_type": model.call_type.rawValue,
                "caller": callerUser,
                "callees": callees
            ]
            self.listener?.receiveUpdate(Notify_Call_Invited, parameter: data)
        }
    }
    
    private func addCallListener(_ callID: String) {
        print("[* Firebase] Start Listen Call, callID: \(callID)")
        let callRef = ref.child("call/\(callID)")
        callRef.removeAllObservers()
        callRef.observe(.value) { snapshot in
            
            guard let callDict = snapshot.value as? [String: Any]
            else {
                
                guard let model = self.modelDict[snapshot.key] else { return }
                guard let myUser = model.getUser(self.user?.uid) else { return }
                guard let otherUser = model.users
                        .filter({ $0.user_id != myUser.user_id })
                        .first else { return }
                
                // if the call data is nil, means this call is ended.
                
                // if the current status is `connecting`:
                // 1. user decline the call
                // 2. user cancel the call
                if model.call_status == .connecting {
                    // caller receive the declined message.
                    if myUser.caller_id == myUser.user_id {
                        self.onReceiveDeclinedNotify(model.call_id, calleeID: otherUser.user_id, type: 1)
                    }
                    // callee receive the canceled message.
                    else {
                        self.onReceiveCanceledNotify(model.call_id, callerID: otherUser.caller_id)
                    }
                }
                
                // if the current status is `calling`
                // 1. user ended the call
                else if model.call_status == .calling {
                    self.onReceiveEndedNotify(model.call_id, otherUserID: otherUser.user_id)
                }
                
                self.modelDict.removeValue(forKey: model.call_id)
                return
            }
            
            guard let callStatus = callDict["call_status"] as? Int,
            callStatus != 1
            else { return }
            
            
            guard let model = FirebaseCallModel.model(with: callDict),
                  let myUser = model.users.filter({ $0.user_id == self.user?.uid }).first,
                  let otherUser = model.users.filter({ $0.user_id != myUser.user_id }).first
            else { return }
            
            let oldModel = self.modelDict[model.call_id]
            
            // MARK: - callee receive call canceld
            if myUser.user_id != myUser.caller_id &&
                myUser.status == .canceled &&
                oldModel?.call_status == .connecting
            {
                self.onReceiveCanceledNotify(model.call_id, callerID: myUser.caller_id)
            }
            
            // MARK: - caller receive call accept
            else if myUser.user_id == myUser.caller_id &&
                        myUser.status == .calling &&
                oldModel?.call_status == .connecting
            {
                self.onReceiveAcceptedNotify(model, calleeID: otherUser.user_id)
            }
            
            // MARK: - caller receive call decline
            else if myUser.user_id == myUser.caller_id &&
                (myUser.status == .declined || myUser.status == .busy) &&
                oldModel?.call_status == .connecting
            {
                if otherUser.status != .declined && otherUser.status != .busy { return }
                let type = otherUser.status == .declined ? 1 : 2
                self.onReceiveDeclinedNotify(model.call_id, calleeID: otherUser.user_id, type: type)
            }
            
            // MARK: - caller and callee receive call ended
            else if model.call_status == .ended &&
                oldModel?.call_status == .calling
            {
                if otherUser.status != .ended { return }
                self.onReceiveEndedNotify(model.call_id, otherUserID: otherUser.user_id)
            }
            
            // MARK: - caller or callee receive connecting timeout
            else if myUser.status == .connectingTimeout &&
                oldModel?.call_status == .connecting
            {
                self.modelDict.removeValue(forKey: model.call_id)
            }
            
            // MARK: - caller or callee receive calling timeout
            else if model.call_status == .calling &&
                oldModel?.call_status == .calling
            {
                if let heartbeatTime = myUser.heartbeat_time,
                   let otherHeartbeatTime = otherUser.heartbeat_time,
                   heartbeatTime > 0,
                   otherHeartbeatTime > 0
                {
                    
                    if heartbeatTime - otherHeartbeatTime > 60 * 1000 {
                        self.onReceiveTimeoutNotify(model.call_id, otherUserID: otherUser.user_id)
                        snapshot.ref.updateChildValues(["call_status": 3])
                    }
                }
                self.modelDict[model.call_id] = model
            }
        }
    }
}

// MARK: - Notify
extension FirebaseManager {
    
    /// callee receive the call canceled
    private func onReceiveCanceledNotify(_ callID: String, callerID: String) {
        let data: [String: Any] = [
            "call_id": callID,
            "caller_id": callerID
        ]
        self.listener?.receiveUpdate(Notify_Call_Canceled, parameter: data)
        self.modelDict.removeValue(forKey: callID)
    }
    
    /// caller receive the accepted
    private func onReceiveAcceptedNotify(_ model: FirebaseCallModel, calleeID: String) {
        let data: [String: Any] = [
            "call_id": model.call_id,
            "callee_id": calleeID
        ]
        self.listener?.receiveUpdate(Notify_Call_Accept, parameter: data)
        self.modelDict[model.call_id] = model
    }
    
    /// caller receive the callee declined the call
    private func onReceiveDeclinedNotify(_ callID: String, calleeID: String, type: Int) {
        let data: [String: Any] = [
            "call_id": callID,
            "callee_id": calleeID,
            "type": type
        ]
        self.listener?.receiveUpdate(Notify_Call_Decline, parameter: data)
        self.modelDict.removeValue(forKey: callID)
    }
    
    /// receive other user ended the call.
    private func onReceiveEndedNotify(_ callID: String, otherUserID: String) {
        let data: [String: Any] = [
            "call_id": callID,
            "user_id": otherUserID
        ]
        self.listener?.receiveUpdate(Notify_Call_End, parameter: data)
        self.modelDict.removeValue(forKey: callID)
    }
    
    private func onReceiveTimeoutNotify(_ callID: String, otherUserID: String) {
        let data: [String: Any] = [
            "call_id": callID,
            "user_id": otherUserID
        ]
        self.listener?.receiveUpdate(Notify_Call_Timeout, parameter: data)
    }
}
