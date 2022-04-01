//
//  CallManager+AcceptTipAction.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/19.
//

import UIKit

extension CallManager: CallAcceptTipViewDelegate {
    func tipViewDidClik(_ userInfo: UserInfo, callType: CallType) {
        if let currentCallVC = currentCallVC {
            currentCallVC.updateCallType(callType, userInfo: userInfo, status: .accept)
            getCurrentViewController()?.present(currentCallVC, animated: true, completion: nil)
        } else {
            let vc: CallMainVC = CallMainVC.loadCallMainVC(callType, userInfo: userInfo, status: .accept)
            currentCallVC = vc
            currentCallStatus = .wait
            currentCallUserInfo = userInfo
            getCurrentViewController()?.present(vc, animated: true, completion: nil)
        }
    }
    
    func tipViewDeclineCall(_ userInfo: UserInfo, callType: CallType) {
        if let userID = userInfo.userID {
            declineCall(userID, callID: nil, type: .decline)
        }
        audioPlayer?.stop()
        currentTipView = nil
    }
    
    func tipViewAcceptCall(_ userInfo: UserInfo, callType: CallType) {
        acceptCall(userInfo, callType: callType)
        currentTipView = nil
    }
    
    func getCurrentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return getCurrentViewController(base: nav.visibleViewController)
            }
            if let tab = base as? UITabBarController {
                return getCurrentViewController(base: tab.selectedViewController)
            }
            if let presented = base?.presentedViewController {
                return getCurrentViewController(base: presented)
            }
            return base
        }
    
}
