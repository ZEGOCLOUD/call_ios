//
//  ListenerUpdater.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

protocol ListenerUpdater: AnyObject {
    func receiveUpdate(_ path: String, parameter: [String : Any])
}
