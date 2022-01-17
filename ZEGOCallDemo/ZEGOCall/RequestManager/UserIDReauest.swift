//
//  UserIDReauest.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/17.
//

import Foundation
import UIKit

let USERID_KEY = "USERID_KEY"

struct UserIDReauest: Request {
    var path = "/v1/user/create_user"
    var method: HTTPMethod = .POST
    typealias Response = RequestStatus
    var parameter = Dictionary<String, AnyObject>()
    
    var type = 1 {
        willSet {
            parameter["type"] = newValue as AnyObject
        }
    }
    
    init() {
        parameter["type"] = 1 as AnyObject
    }
}
