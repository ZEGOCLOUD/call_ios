//
//  ListenerManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

class ListenerManager {

    
    static let shared = ListenerManager()
}

extension ListenerManager: Listener {
    func registerListener(_ listener: AnyObject, for path: String, callback: (Result<Any, ZegoError>) -> Void) {
        
    }
    
    func removeListener(_ listener: AnyObject, for path: String) {
        
    }
}

extension ListenerManager: ListenerUpdater {
    func receiveUpdate(_ path: String, parameter: [String : Any]) {
        
    }
}
