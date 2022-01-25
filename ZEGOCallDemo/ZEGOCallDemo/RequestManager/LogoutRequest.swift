//
//  LogoutRequest.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/17.
//

import Foundation

struct LogoutRequest : Request {
    var path = "/v1/user/logout"
    var method: HTTPMethod = .POST
    typealias Response = RequestStatus
    var parameter = Dictionary<String, AnyObject>()
    
    var userID = "" {
        willSet {
            parameter["id"] = newValue as AnyObject
        }
    }
    
    var type = 1 {
        willSet {
            parameter["type"] = newValue as AnyObject
        }
    }
    
    init() {
        parameter["type"] = 1 as AnyObject
    }
}
