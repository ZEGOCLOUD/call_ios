//
//  InvitationCommand.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/24.
//

import Foundation

enum CustomCommandType : Int, Codable {
    case call = 1
    case cancel = 2
    case reply = 3
    case end = 4
}

struct CustomCommandContent : Codable {
    var user_info = Dictionary<String, String>() ///
    var response_type : Int = 1 /// 1:agree  2:refused
    var call_type : Int = 1 /// 1:voice 2:video
}

class CustomCommand : NSObject, Codable {
    
    var targetUserIDs: [String] = []
    var type: CustomCommandType = .call
    var content: CustomCommandContent?
    
    enum CodingKeys: String, CodingKey {
        case targetUserIDs = "target"
        case type = "action_type"
        case content = "content"
    }
    
    init(_ type: CustomCommandType) {
        self.type = type
    }
    
    func json() -> String? {
        let jsonStr = ZegoJsonTool.modelToJson(toString: self)
        return jsonStr
    }
}
