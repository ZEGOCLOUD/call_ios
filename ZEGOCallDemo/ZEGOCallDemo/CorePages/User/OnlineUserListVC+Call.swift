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
        guard let userID = CallManager.shared.localUserInfo?.userID else { return }
        CallManager.shared.getToken(userID) { result in
            switch result {
            case .success(let token):
                switch type {
                case .voice:
                    CallManager.shared.callUser(userInfo, token: token as! String, callType: .voice) { result in
                        switch result {
                        case .success():
                            break
                        case .failure(let error):
                            TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                        }
                    }
                case .video:
                    CallManager.shared.callUser(userInfo, token: token as! String, callType: .video) { result in
                        switch result {
                        case .success():
                            break
                        case .failure(let error):
                            TipView.showWarn(String(format: ZGLocalizedString("call_page_call_fail"), error.code))
                            break
                        }
                    }
                }
            case .failure(_):
                print("call fail")
                break
            }
        }
    }
}
