//
//  CallManager+Minimized.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/22.
//

import Foundation

extension CallManager: MinimizedDisplayManagerDelegate {
    
    func didClickAudioMinimizeView() {
        showCallPage(.voice)
    }
    
    func didClickVideoMinimizedView() {
        showCallPage(.video)
    }
    
    func showCallPage(_ callType: CallType) {
        CallManager.shared.minmizedManager.viewHiden = true
        if let currentCallVC = currentCallVC,
           let currentCallUserInfo = currentCallUserInfo
        {
            if currentCallStatus == .calling {
                currentCallVC.updateCallType(callType, userInfo: currentCallUserInfo, status: .calling)
            } else if currentCallStatus == .waitAccept {
                currentCallVC.updateCallType(callType, userInfo: currentCallUserInfo, status: .take)
            } else if currentCallStatus == .wait {
                currentCallVC.updateCallType(callType, userInfo: currentCallUserInfo, status: .accept)
            }
            getCurrentViewController()?.present(currentCallVC, animated: true, completion: nil)
        }
    }
}
