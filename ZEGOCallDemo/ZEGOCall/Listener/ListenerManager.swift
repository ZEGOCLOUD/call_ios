//
//  ListenerManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

class ListenerHandler {
    var path: String?
    weak var listener: AnyObject?
    var callback: NotifyCallback?
}

class ListenerManager {
    
    static let shared = ListenerManager()
    
    private var listenerDict = [String: [ListenerHandler]]()
    
    private var _lock = os_unfair_lock()
}

extension ListenerManager: Listener {
    func registerListener(_ listener: AnyObject, for path: String, callback: @escaping NotifyCallback) {
        lock()
        defer {
            unlock()
        }
        var arrary = listenerDict[path]
        if arrary == nil {
            arrary = [ListenerHandler]()
        }
        
        for handler in arrary! {
            guard let oldListener = handler.listener else { break }
            if oldListener === listener {
                handler.listener = listener
                handler.callback = callback
                return
            }
        }
        
        let handler = ListenerHandler()
        handler.path = path
        handler.listener = listener
        handler.callback = callback
        
        arrary?.append(handler)
        listenerDict[path] = arrary
    }
    
    func removeListener(_ listener: AnyObject, for path: String) {
        lock()
        defer {
            unlock()
        }
        let arrary = listenerDict[path]
        if arrary?.count == 0 { return }
        guard var arrary = arrary else { return }
        arrary = arrary.filter { $0.listener !== listener }
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
        var tempArrary = [ListenerHandler]()
        for handler in arrary {
            if handler.listener == nil {
                continue
            }
            tempArrary.append(handler)
            if let callback = handler.callback {
                callback(parameter)
            }
        }
        listenerDict[path] = tempArrary
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
