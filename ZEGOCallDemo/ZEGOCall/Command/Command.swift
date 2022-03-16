//
//  Command.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

protocol Command {
    var path: String { get set }
    var parameter: [String : String] { get set }
}
