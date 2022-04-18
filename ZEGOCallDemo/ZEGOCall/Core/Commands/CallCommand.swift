//
//  CallCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/18.
//

import Foundation

class CallCommand: Command {
    var path: String = API_Start_Call
    
    var parameter = [String : AnyObject]()
        
    var callID: String? {
        willSet {
            parameter["call_id"] = newValue as AnyObject
        }
    }
    
    var caller: [String: Any]? {
        willSet {
            parameter["caller"] = newValue as AnyObject
        }
    }
    
    var callees: [[String: Any]]? {
        willSet {
            parameter["callees"] = newValue as AnyObject
        }
    }
    
    var type: CallType? {
        willSet {
            parameter["type"] = newValue?.rawValue as AnyObject
        }
    }
}
