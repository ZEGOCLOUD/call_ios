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
        
        if CallManager.shared.currentCallStatus != .free {
            HUDHelper.showMessage(message: ZGLocalizedString("call_page_call_unable_initiate"))
            return
        }
        guard let token = TokenManager.shared.token?.token else { return }
        switch type {
        case .voice:
            CallManager.shared.callUser(userInfo, token: token, callType: .voice) { result in
                switch result {
                case .success():
                    break
                case .failure(let error):
                    TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                }
            }
        case .video:
            CallManager.shared.callUser(userInfo, token: token, callType: .video) { result in
                switch result {
                case .success():
                    break
                case .failure(let error):
                    TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                    break
                }
            }
        }
    }
}
