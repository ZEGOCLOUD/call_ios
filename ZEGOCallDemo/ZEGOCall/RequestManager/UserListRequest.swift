//
//  UserListRequest.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/17.
//

import Foundation
import UIKit

struct UserListRequest: Request {
    var path = "/v1/user/get_user_list"
    var method: HTTPMethod = .POST
    typealias Response = UserInfoList
    var parameter = Dictionary<String, AnyObject>()
    
    var pageNum = 1 {
        willSet {
            parameter["page_num"] = newValue as AnyObject
        }
    }
    var from = "" {
        willSet {
            parameter["from"] = newValue as AnyObject
        }
    }
    var direct = 0 {
        willSet {
            parameter["direct"] = newValue as AnyObject
        }
    }
    var type = 1 {
        willSet {
            parameter["type"] = newValue as AnyObject
        }
    }
    
    init() {
        parameter["page_num"] = 100 as AnyObject
        parameter["type"] = 1 as AnyObject
        parameter["direct"] = 0 as AnyObject
    }
}
