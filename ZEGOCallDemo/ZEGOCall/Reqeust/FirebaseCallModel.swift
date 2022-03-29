//
//  FirebaseCallModel.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/23.
//

import Foundation

enum FirebaseCallStatus: Int {
    case connecting = 1
    case calling = 2
    case ended = 3
    case declined = 4
    case busy = 5
    case canceled = 6
    case connectingTimeout = 7
    case callingTimeout = 8
}

enum FirebaseCallType: Int {
    case voice = 1
    case video = 2
}

class FirebaseCallUser {
    var caller_id: String = ""
    var user_id: String = ""
    var user_name: String?
    var start_time: Int?
    var connected_time: Int?
    var finish_time: Int?
    var heartbeat_time: Int?
    var status: FirebaseCallStatus = .connecting
    
    func copy() -> FirebaseCallUser {
        let copy = FirebaseCallUser()
        copy.caller_id = caller_id
        copy.user_id = user_id
        copy.user_name = user_name
        copy.start_time = start_time
        copy.connected_time = connected_time
        copy.finish_time = finish_time
        copy.heartbeat_time = heartbeat_time
        copy.status = status
        return copy
    }
}

class FirebaseCallModel {
    var call_id: String = ""
    var call_type: FirebaseCallType = .voice
    var call_status: FirebaseCallStatus = .connecting
    var users = [FirebaseCallUser]()
    
    static func model(with dict: [String: Any]) -> FirebaseCallModel? {
        let model = FirebaseCallModel()
        guard let callID = dict["call_id"] as? String,
              let callTypeOld = dict["call_type"] as? Int,
              let callType = FirebaseCallType(rawValue: callTypeOld),
              let callStatusOld = dict["call_status"] as? Int,
              let callStatus = FirebaseCallStatus.init(rawValue: callStatusOld),
              let usersDict = dict["users"] as? [String: [String: Any]]
        else {
            return nil
        }
        
        model.call_id = callID
        model.call_type = callType
        model.call_status = callStatus
        
        for (userID, userDict) in usersDict {
            guard let callerID = userDict["caller_id"] as? String,
                  let startTime = userDict["start_time"] as? Int,
                  let statusOld = userDict["status"] as? Int,
                  let status = FirebaseCallStatus.init(rawValue: statusOld)
            else {
                return nil
            }
            let user = FirebaseCallUser()
            user.user_id = userID
            user.user_name = userDict["user_name"] as? String
            user.caller_id = callerID
            user.start_time = startTime
            user.status = status
            
            user.connected_time = userDict["connected_time"] as? Int
            user.finish_time = userDict["finish_time"] as? Int
            user.heartbeat_time = userDict["heartbeat_time"] as? Int
            
            model.users.append(user)
        }
        
        return model
    }
    
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
        dict["call_type"] = call_type.rawValue
        dict["call_status"] = call_status.rawValue
        
        var usersDict = [String: Any]()
        for user in users {
            var userDict = [String: Any]()
            
            userDict["caller_id"] = user.caller_id
            userDict["user_id"] = user.user_id
            userDict["user_name"] = user.user_name
            userDict["start_time"] = user.start_time
            userDict["connected_time"] = user.connected_time
            userDict["finish_time"] = user.finish_time
            userDict["heartbeat_time"] = user.heartbeat_time
            userDict["status"] = user.status.rawValue

            usersDict[user.user_id] = userDict
        }
        
        dict["users"] = usersDict
        
        return dict
    }
}
