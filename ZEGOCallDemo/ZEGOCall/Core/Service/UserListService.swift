//
//  UserListService.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/17.
//

import Foundation


class UserListService: NSObject {
    
    var userList = Array<UserInfo>()
    
    // MARK: - Public
    func getUserList(_ fromOrderID: String?, callback: UserListCallback?) {
        var request = UserListRequest()
        if let orderID = fromOrderID {
            request.from = orderID
        }
        RequestManager.shared.getUserListRequest(request: request) { userInfoList in
            guard let userInfoList = userInfoList else { return }
            if request.from.count > 0 {
                self.userList.append(contentsOf: userInfoList.userInfoArray)
            } else {
                self.userList = userInfoList.userInfoArray
            }
            guard let callback = callback else { return }
            callback(.success(userInfoList.userInfoArray))
        } failure: { roomInfoList in
            guard let callback = callback else { return }
            callback(.failure(.failed))
        }
    }
    
    // MARK: private method
    private func heartBeatRequest() {
        var request = HeartBeatRequest()
        request.userID = RoomManager.shared.userService.localUserInfo?.userID ?? ""
        RequestManager.shared.heartBeatRequest(request: request) { requestStatus in
        } failure: { requestStatus in
        }
    }
}
