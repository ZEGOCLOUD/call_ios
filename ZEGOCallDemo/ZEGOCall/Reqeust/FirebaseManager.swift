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
                addUser(newValue!)
            }
        }
    }
    
    private var fcmToken: String?
    private var ref = Database.database(url: "https://zegocall-604e2-default-rtdb.asia-southeast1.firebasedatabase.app/").reference()
    
    private var functionsMap = [String : functionType]()
    
    private override init() {
        super.init()
        
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
        guard let callback = callback else { return }
        do {
            try Auth.auth().signOut()
            callback(.success(()))
        } catch {
            callback(.failure(.failed))
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
    func addUser(_ user: User) {
        Messaging.messaging().token { token, error in
            guard let token = token else {
                return
            }
            self.fcmToken = token
            // setup database
            let data = [
                "uid" : user.uid,
                "display_name" : user.displayName,
                "tokenID" : token
            ]
            let userRef = self.ref.child("online_user").child(user.uid)
            userRef.setValue(data)
            userRef.onDisconnectRemoveValue()
        }

    }
}
