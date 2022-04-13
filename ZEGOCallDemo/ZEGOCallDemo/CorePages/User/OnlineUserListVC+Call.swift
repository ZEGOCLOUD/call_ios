//
//  OnlineUserListVC+Call.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import Foundation
import AVFoundation

extension OnlineUserListVC: OnlineUserListCellDelegate {
    func startCall(_ type: CallType, userInfo: UserInfo) {
        if !DeviceTool.shared.cameraPermission {
            AuthorizedCheck.showCameraUnauthorizedAlert(self)
            return
        }
        if !DeviceTool.shared.micPermission {
            AuthorizedCheck.showMicrophoneUnauthorizedAlert(self)
            return
        }
        if CallManager.shared.currentCallStatus != .free {
            HUDHelper.showMessage(message: ZGAppLocalizedString("call_page_call_unable_initiate"))
            return
        }
        if CallManager.shared.token == nil {
            HUDHelper.showMessage(message: ZGAppLocalizedString("token_is_not_exist"))
            TokenManager.shared.getToken()
            return
        }
        switch type {
        case .voice:
            CallManager.shared.callUser(userInfo, callType: .voice) { result in
                switch result {
                case .success():
                    break
                case .failure(let error):
                    if case .tokenExpired = error {
                        TokenManager.shared.getToken()
                    }
                    TipView.showWarn(String(format: ZGAppLocalizedString("call_page_call_fail"), error.code))
                }
            }
        case .video:
            CallManager.shared.callUser(userInfo, callType: .video) { result in
                switch result {
                case .success():
                    break
                case .failure(let error):
                    TipView.showWarn(String(format: ZGAppLocalizedString("call_page_call_fail"), error.code))
                    break
                }
            }
        }
    }
}
