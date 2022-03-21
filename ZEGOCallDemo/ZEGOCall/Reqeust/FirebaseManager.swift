//
//  FirebaseManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

class FirebaseManager: NSObject {
    
    private typealias functionType = ([String : AnyObject], RequestCallback?) -> ()
    
    static let shared = FirebaseManager()
    weak var listener: ListenerUpdater? = ListenerManager.shared
    
    private var functionsMap = [String : functionType]()
    
    private override init() {
        super.init()
        
        // add functions
        functionsMap[API_GetUser] = getUser
        functionsMap[API_Login] = login
    }
}

extension FirebaseManager: RequestProtocol {
    func request(_ path: String, parameter: [String : AnyObject], callback: RequestCallback?) {
        print(path)
        guard let function = functionsMap[path] else { return }
        function(parameter, callback)
    }
}

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
            var result = [String : String]()
            result["id"] = user.uid
            result["name"] = user.displayName
            callback(.success(result))
        }
    }
    
    private func getUser(_ parameter: [String: AnyObject], callback: RequestCallback?) {
        guard let callback = callback else {
            return
        }
        let auth = Auth.auth()
        guard let currentUser = auth.currentUser else {
            callback(.failure(.failed))
            return
        }
        
        var result = [String : String]()
        result["id"] = currentUser.uid
        result["name"] = currentUser.displayName
        callback(.success(result))
    }
}
