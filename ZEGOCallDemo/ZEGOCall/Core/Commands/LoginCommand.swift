//
//  LoginCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/16.
//

import Foundation

class LoginCommand: Command {
    let path: String = API_Login
    
    var parameter = [String : AnyObject]()
    
    var userID: String? {
        willSet {
            parameter["id"] = newValue as AnyObject
        }
    }
    var token: String? {
        willSet {
            parameter["token"] = newValue as AnyObject
        }
    }
}
