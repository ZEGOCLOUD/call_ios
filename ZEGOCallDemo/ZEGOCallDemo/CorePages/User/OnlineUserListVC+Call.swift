//
//  OnlineUserListVC+Call.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import Foundation

extension OnlineUserListVC: OnlineUserListCellDelegate {
    func startCall(_ type: CallType, userInfo: UserInfo) {
        switch type {
        case .audio:
            if let userID = userInfo.userID {
                RoomManager.shared.userService.callToUser(userID, type: .audio) { result in
                    switch result {
                    case .success():
                        CallBusiness.shared.startCall(userInfo, callType: .audio)
                    case .failure(let code):
                        break
                    }
                }
            }
        case .video:
            if let userID = userInfo.userID {
                RoomManager.shared.userService.callToUser(userID, type: .video) { result in
                    switch result {
                    case .success():
                        CallBusiness.shared.startCall(userInfo, callType: .video)
                    case .failure(let code):
                        break
                    }
                }
            }
        }
    }
}
