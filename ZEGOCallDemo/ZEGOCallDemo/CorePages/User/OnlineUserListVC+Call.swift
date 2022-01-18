//
//  OnlineUserListVC+Call.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import Foundation

extension OnlineUserListVC: OnlineUserListCellDelegate {
    func startCall(_ type: CallActionType, userInfo: UserInfo) {
        switch type {
        case .phone:
            if let userID = userInfo.userID {
                RoomManager.shared.userService.callToUser(userID, type: .audio) { result in
                    switch result {
                    case .success():
                        let vc: CallMainVC = CallMainVC.loadCallMainVC(.phone, userInfo: userInfo, status: .take)
                        self.present(vc, animated: true, completion: nil)
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
                        let vc: CallMainVC = CallMainVC.loadCallMainVC(.video, userInfo: userInfo, status: .take)
                        self.present(vc, animated: true, completion: nil)
                    case .failure(let code):
                        break
                    }
                }
            }
        }
    }
}
