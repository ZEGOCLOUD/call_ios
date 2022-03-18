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

class FirebaseManager: NSObject, RequestProtocol {
    
    static let shared = FirebaseManager()
    
    weak var listener: ListenerUpdater? = ListenerManager.shared
    
    func request(_ path: String, parameter: [String : AnyObject], callback: RequestCallback?) {
            
        
        
    }
}
