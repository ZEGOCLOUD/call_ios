//
//  ZegoListen.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

protocol Listener {
    func registerListener(_ listener: AnyObject, for path: String, callback: RequestCallback)
    
    func removeListener(_ listener: AnyObject, for path: String)
}
