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
                let rtcToken = AppToken.getRtcToken(withRoomID: userID)
                guard let rtcToken = rtcToken else { return }
                ServiceManager.shared.callService.callUser(userID, token:rtcToken, type: .voice) { result in
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
                let rtcToken = AppToken.getRtcToken(withRoomID: userID)
                guard let rtcToken = rtcToken else { return }
                ServiceManager.shared.callService.callUser(userID, token:rtcToken, type: .video) { result in
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
