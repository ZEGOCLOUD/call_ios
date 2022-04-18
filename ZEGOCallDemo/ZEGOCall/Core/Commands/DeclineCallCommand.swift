//
//  DeclineCallCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/23.
//

import Foundation

class DeclineCallCommand: Command {
    var path: String = API_Decline_Call
    
    var parameter = [String : AnyObject]()
    
    var userID: String? {
        willSet {
            parameter["id"] = newValue as AnyObject
        }
    }
    
    var callID: String? {
        willSet {
            parameter["call_id"] = newValue as AnyObject
        }
    }
    
    var callerID: String? {
        willSet {
            parameter["caller_id"] = newValue as AnyObject
        }
    }
    
    var type: DeclineType? {
        willSet {
            parameter["type"] = newValue?.rawValue as AnyObject
        }
    }
    
}
