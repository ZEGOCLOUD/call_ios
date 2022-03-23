//
//  AcceptCallCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/23.
//

import Foundation

class AcceptCallCommand: Command {
    var path: String = API_Accept_Call
    
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
