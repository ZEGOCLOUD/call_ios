//
//  TokenCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/29.
//

import Foundation

class TokenCommand: Command {
    let path: String = API_Get_Token
    
    var parameter = [String : AnyObject]()
    
    var userID: String? {
        willSet {
            parameter["id"] = newValue as AnyObject
        }
    }
    
    var effectiveTimeInSeconds: Int? {
        willSet {
            parameter["effective_time"] = newValue as AnyObject
        }
    }
}
