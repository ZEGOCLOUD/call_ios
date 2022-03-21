//
//  CommandManager.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

class CommandManager {
    static let shared = CommandManager()
    
    private var service: RequestProtocol = FirebaseManager.shared
    
    func execute(_ command: Command, callback: RequestCallback?) {
        service.request(command.path, parameter: command.parameter, callback: callback)
    }
}
