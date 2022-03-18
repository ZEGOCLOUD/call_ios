//
//  File.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/18.
//

import Foundation

class UserListCommand: Command {
    var path: String = "/user/get_users"
    
    var parameter = [String : AnyObject]()
    
    var userID: String? {
        willSet {
            parameter["id"] = newValue as AnyObject
        }
    }
    
    var fromOrderID: String? {
        willSet {
            parameter["from"] = newValue as AnyObject
        }
    }
    
    var count: Int = 100 {
        willSet {
            parameter["count"] = newValue as AnyObject
        }
    }
}
