//
//  RespondCallCommand.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/18.
//

import Foundation

class RespondCallCommand: Command {
    var path: String = "/call/respond_call"
    
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
    
    var type: ResponseType? {
        willSet {
            parameter["type"] = newValue as AnyObject
        }
    }
    
    
}
