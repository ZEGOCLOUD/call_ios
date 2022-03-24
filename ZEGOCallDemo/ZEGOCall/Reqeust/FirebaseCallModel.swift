//
//  FirebaseCallModel.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/23.
//

import Foundation

class FirebaseCallUser {
    var caller_id: String?
    var user_id: String?
    var start_time: Int?
    var connected_time: Int?
    var finish_time: Int?
    var heartbeat_time: Int?
    var status: Int = 1
    
    func copy() -> FirebaseCallUser {
        let copy = FirebaseCallUser()
        copy.caller_id = caller_id
        copy.user_id = user_id
        copy.start_time = start_time
        copy.connected_time = connected_time
        copy.finish_time = finish_time
        copy.heartbeat_time = heartbeat_time
        copy.status = status
        return copy
    }
}

class FirebaseCallModel {
    var call_id: String?
    var call_type: Int = 1
    var call_status: Int = 1
    var users = [FirebaseCallUser]()
    
    func getUser(_ userID: String?) -> FirebaseCallUser? {
        guard let userID = userID else {
            return nil
        }

        for user in users {
            if user.user_id == userID { return user }
        }
        return nil
    }
    
    func copy() -> FirebaseCallModel {
        let copy = FirebaseCallModel()
        copy.call_id = call_id
        copy.call_type = call_type
        copy.call_status = call_status
        for user in users {
            copy.users.append(user.copy())
        }
        return copy
    }
    
    func toDict() -> [String: Any] {
        var dict = [String: Any]()
        
        dict["call_id"] = call_id
        dict["call_type"] = call_type
        dict["call_status"] = call_status
        
        var usersDict = [String: Any]()
        for user in users {
            var userDict = [String: Any]()
            
            userDict["caller_id"] = user.caller_id
            userDict["user_id"] = user.user_id
            userDict["start_time"] = user.start_time
            userDict["connected_time"] = user.connected_time
            userDict["finish_time"] = user.finish_time
            userDict["heartbeat_time"] = user.heartbeat_time
            userDict["status"] = user.status

            if let user_id = user.user_id {
                usersDict[user_id] = userDict
            }
        }
        
        dict["users"] = usersDict
        
        return dict
    }
}
