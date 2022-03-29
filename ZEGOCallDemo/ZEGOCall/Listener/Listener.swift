//
//  ZegoListen.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

protocol Listener {
    @discardableResult
    func addListener(_ path: String, listener: @escaping NotifyCallback) -> UUID
    func removeListener(_ uid: UUID, for path: String)
}
