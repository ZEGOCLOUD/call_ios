//
//  EndCallCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/18.
//

import Foundation

class EndCallCommand: Command {
    var path: String = API_End_Call
    
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
}
