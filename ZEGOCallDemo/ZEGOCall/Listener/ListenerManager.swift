//
//  ListenerManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

class ListenerHandler {
    var path: String?
    var uid: UUID
    var listener: NotifyCallback?
    
    init(uid: UUID) {
        self.uid = uid
    }
}

class ListenerManager {
    
    static let shared = ListenerManager()
    
    private var listenerDict = [String: [ListenerHandler]]()
    
    private var _lock = os_unfair_lock()
}

extension ListenerManager: Listener {
    func addListener(_ path: String, listener: @escaping NotifyCallback) -> UUID {
        lock()
        defer {
            unlock()
        }
        var arrary = listenerDict[path]
        if arrary == nil {
            arrary = [ListenerHandler]()
        }
        
        let handler = ListenerHandler(uid: UUID())
        handler.path = path
        handler.listener = listener
        
        arrary?.append(handler)
        listenerDict[path] = arrary
        
        return handler.uid
    }
    
    func removeListener(_ uid: UUID, for path: String) {
        lock()
        defer {
            unlock()
        }
        
        let arrary = listenerDict[path]
        guard var arrary = arrary, arrary.count > 0 else { return }
        
        arrary = arrary.filter { $0.uid != uid }
        
        listenerDict[path] = arrary
    }
}

extension ListenerManager: ListenerUpdater {
    func receiveUpdate(_ path: String, parameter: [String : Any]) {
        lock()
        defer {
            unlock()
        }
        let arrary = listenerDict[path]
        guard let arrary = arrary else { return }
        
        for handler in arrary {
            guard let listener = handler.listener else { continue }
            listener(parameter)
        }
    }
}

extension ListenerManager {
    func lock() {
        os_unfair_lock_lock(&_lock)
    }
    func unlock() {
        os_unfair_lock_unlock(&_lock)
    }
}
