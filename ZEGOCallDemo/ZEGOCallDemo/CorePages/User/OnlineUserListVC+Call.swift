//
//  OnlineUserListVC+Call.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import Foundation

extension OnlineUserListVC: OnlineUserListCellDelegate {
    func startCall(_ type: CallType, userInfo: UserInfo) {
        if CallBusiness.shared.currentCallStatus != .free { return }
        switch type {
        case .voice:
            if let userID = userInfo.userID {
                let token = AppToken.getToken(withUserID: CallBusiness.shared.localUserID)
                guard let token = token else { return }
                RoomManager.shared.userService.callUser(userID, token:token, type: .voice) { result in
                    switch result {
                    case .success():
                        CallBusiness.shared.startCall(userInfo, callType: .voice)
                    case .failure(let error):
                        TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                        break
                    }
                }
            }
        case .video:
            if let userID = userInfo.userID {
                let token = AppToken.getToken(withUserID: CallBusiness.shared.localUserID)
                guard let token = token else { return }
                RoomManager.shared.userService.callUser(userID, token:token, type: .video) { result in
                    switch result {
                    case .success():
                        CallBusiness.shared.startCall(userInfo, callType: .video)
                    case .failure(let error):
                        TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                        break
                    }
                }
            }
        }
    }
}
