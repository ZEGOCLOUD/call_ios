//
//  RoomInfoList.swift
//  ZEGOLiveDemo
//
//  Created by Larry on 2021/12/27.
//

import Foundation

struct RoomInfoList {
    var roomInfoArray = Array<RoomInfo>()
    var hasNextPage = false
    var requestStatus = RequestStatus(json: Dictionary<String, Any>())
    
    init() {
        
    }
    
    init(json: Dictionary<String, Any>) {
        guard let dataJson = json["data"] as? [String : Any] else { return }
        guard let roomInfoList = dataJson["room_list"] as? Array<[String : Any]> else { return }
        roomInfoArray = roomInfoList.map{
            ZegoJsonTool.dictionaryToModel(type: RoomInfo.self, dict: $0) ?? RoomInfo()
        }
        requestStatus = RequestStatus(json: json)
    }
}

extension RoomInfoList: Decodable {
    static func parse(_ json: Dictionary<String, Any>) -> RoomInfoList? {
        return RoomInfoList(json: json)
    }
}
