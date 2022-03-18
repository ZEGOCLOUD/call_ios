//
//  CallCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/18.
//

import Foundation

class CallCommand: Command {
    var path: String = "/call/start_call"
    
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
    
    var invitees: [String]? {
        willSet {
            parameter["invitees"] = newValue as AnyObject
        }
    }
    
    var type: CallType? {
        willSet {
            parameter["type"] = newValue as AnyObject
        }
    }
}
