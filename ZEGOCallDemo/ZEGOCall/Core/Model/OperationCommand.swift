//
//  Command.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/24.
//

import Foundation
import UIKit

struct OperationAttributeType : OptionSet {
    let rawValue: Int
    static let coHost = OperationAttributeType(rawValue: 1)
    static let requestCoHost = OperationAttributeType(rawValue: 2)
    // the -1 every bit is 1
    static let all = OperationAttributeType(rawValue: -1)
}

enum OperationActionType : Int, Codable {
    case mic = 100
    case camera = 101
}

struct OperationAction : Codable {
    var seq: Int = 0
    var type: OperationActionType?
    var targetID: String = ""
    var operatorID: String = ""
    
    enum CodingKeys: String, CodingKey {
        case seq = "seq"
        case type = "type"
        case targetID = "target_id"
        case operatorID = "operator_id"
    }
}

class OperationCommand : NSObject, Codable {
    var action: OperationAction = OperationAction()
    
    enum CodingKeys: String, CodingKey {
        case action = "action"
    }
    
    func json() -> String? {
        let jsonStr = ZegoJsonTool.modelToJson(toString: self)
        return jsonStr
    }
    
    func attributes(_ type: OperationAttributeType) -> [String: String] {
        var attributes: [String: String] = [:]
        if let actionJson = ZegoJsonTool.modelToJson(toString: action) {
            attributes["action"] = actionJson
        }
        
        return attributes
    }
    
    func isSeqValid(_ seq: Int) -> Bool {
        if seq == 0 && action.seq == 0 { return true }
        if seq > 0 && seq > action.seq { return true }
        return false
    }
}

extension OperationCommand: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = OperationCommand()
        copy.action = OperationAction()
        copy.action.seq = self.action.seq
        return copy
    }
}
