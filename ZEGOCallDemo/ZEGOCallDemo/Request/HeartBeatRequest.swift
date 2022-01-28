//
//  HeartBeatRequest.swift
//  ZEGOLiveDemo
//
//  Created by Larry on 2021/12/27.
//

import Foundation

struct HeartBeatRequest : Request {
    var path = "/v1/user/heartbeat"
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
