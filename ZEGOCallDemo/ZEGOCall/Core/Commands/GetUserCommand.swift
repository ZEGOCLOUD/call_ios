//
//  GetUserCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/21.
//

import Foundation

class GetUserCommand: Command {
    let path: String = API_Get_User
    var parameter = [String : AnyObject]()
    
    var userID: String? {
        willSet {
            parameter["id"] = newValue as AnyObject
        }
    }
}
