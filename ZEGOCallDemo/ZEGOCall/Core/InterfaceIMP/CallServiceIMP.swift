//
//  CallServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

class CallServiceIMP: NSObject, CallService {
    
    var delegate: CallServiceDelegate?
    
    var status: CallStatus = .free
    
    var callInfo: CallInfo?
    
    func callUser(_ userID: String, token: String, type: CallType, callback: RoomCallback?) {
        
    }
    
    func cancelCall(userID: String, cancelType: CancelType, callback: RoomCallback?) {
        
    }
    
    func respondCall(_ userID: String, token: String, responseType: CallResponseType, callback: RoomCallback?) {
        
    }
    
    func endCall(callback: RoomCallback?) {
        
    }
    
    
}
