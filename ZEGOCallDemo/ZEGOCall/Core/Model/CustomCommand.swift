//
//  InvitationCommand.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/24.
//

import Foundation

struct CustomCommandContent : Codable {
    var accept: Bool
}

class CustomCommand : NSObject, Codable {
    enum CustomCommandType : Int, Codable {
        case invitation = 1
        case respondInvitation = 2
    }
    
    var targetUserIDs: [String] = []
    var type: CustomCommandType?
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
