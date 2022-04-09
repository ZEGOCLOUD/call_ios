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
                TokenManager.shared.getToken(CallBusiness.shared.localUserID) { result in
                    if result.isSuccess {
                        let token: String? = result.success
                        guard let token = token else {
                            print("token is nil")
                            return
                        }
                        RoomManager.shared.userService.callUser(userID, token:token, type: .voice) { result in
                            switch result {
                            case .success():
                                CallBusiness.shared.startCall(userInfo, callType: .voice)
                            case .failure(let error):
                                TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                                break
                            }
                        }
                    } else {
                        HUDHelper.showMessage(message: "get token fail")
                    }
                }
            }
        case .video:
            if let userID = userInfo.userID {
                TokenManager.shared.getToken(CallBusiness.shared.localUserID) { result in
                    if result.isSuccess {
                        let token: String? = result.success
                        guard let token = token else {
                            print("token is nil")
                            return
                        }
                        RoomManager.shared.userService.callUser(userID, token:token, type: .video) { result in
                            switch result {
                            case .success():
                                CallBusiness.shared.startCall(userInfo, callType: .video)
                            case .failure(let error):
                                TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                                break
                            }
                        }
                    } else {
                        HUDHelper.showMessage(message: "get token fail")
                    }
                }
            }
        }
    }
}
