//
//  Command.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

protocol Command {
    var path: String { get }
    var parameter: [String : AnyObject] { get }
}

extension Command {
    func execute(callback: RequestCallback?) {
        CommandManager.shared.execute(self, callback: callback)
    }
}
