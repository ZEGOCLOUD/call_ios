//
//  RequestMananger.swift
//  ZEGOLiveDemo
//
//  Created by Larry on 2021/12/27.
//

import Foundation
struct RequestManager {
    static let shared: RequestManager = RequestManager()
    
    func getUserIDRequest(request: UserIDReauest, success:@escaping(RequestStatus?)->(), failure:@escaping(_ requestStatus: RequestStatus?)->()){
        NetworkManager.shareManage.send(request){ requestStatus in
            if requestStatus?.code == 0 {
                success(requestStatus)
            } else {
                failure(requestStatus)
            }
        }
    }
    
    //  get room list
    func getUserListRequest(request: UserListRequest, success:@escaping(UserInfoList?)->(), failure:@escaping(_ userInfoList: UserInfoList?)->()){
        NetworkManager.shareManage.send(request){ userInfoList in
            if userInfoList?.requestStatus.code == 0 {
                success(userInfoList)
            } else {
                failure(userInfoList)
            }
        }
    }
    
    
    func loginRequest(request: LoginRequest, success:@escaping(RequestStatus?)->(), failure:@escaping(_ requestStatus: RequestStatus?)->()){
        NetworkManager.shareManage.send(request){ requestStatus in
            if requestStatus?.code == 0 {
                success(requestStatus)
            } else {
                failure(requestStatus)
            }
        }
    }
    
    func logoutRequest(request: LogoutRequest, success:@escaping(RequestStatus?)->(), failure:@escaping(_ requestStatus: RequestStatus?)->()){
        NetworkManager.shareManage.send(request){ requestStatus in
            if requestStatus?.code == 0 {
                success(requestStatus)
            } else {
                failure(requestStatus)
            }
        }
    }
    
    // heart beat
    func heartBeatRequest(request: HeartBeatRequest, success:@escaping(RequestStatus?)->(), failure:@escaping(_ requestStatus: RequestStatus?)->()){
        NetworkManager.shareManage.send(request){ requestStatus in
            if (requestStatus?.code == 0) {
                success(requestStatus)
            } else {
                failure(requestStatus)
            }
        }
    }
    
}








