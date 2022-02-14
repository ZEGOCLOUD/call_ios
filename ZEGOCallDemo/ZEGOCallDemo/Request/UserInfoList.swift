//
//  UserInfoList.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/17.
//

import Foundation

struct UserInfoList {
    var userInfoArray = Array<UserInfo>()
    var hasNextPage = false
    var requestStatus = RequestStatus(json: Dictionary<String, Any>())
    
    init() {
        
    }
    
    init(json: Dictionary<String, Any>) {
        guard let dataJson = json["data"] as? [String : Any] else { return }
        guard let userInfoList = dataJson["user_list"] as? Array<[String : Any]> else { return }
        userInfoArray = userInfoList.map{ UserInfo(json: $0) }
        requestStatus = RequestStatus(json: json)
    }
}

extension UserInfoList: Decodable {
    static func parse(_ json: Dictionary<String, Any>) -> UserInfoList? {
        return UserInfoList(json: json)
    }
}
