//
//  CallBusiness+CallKit.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation
import ZegoExpressEngine
import UIKit

extension CallManager {
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        // Application is back in the foreground
        if !appIsActive {
            if currentCallStatus == .calling {
                if !minmizedManager.viewHiden {
                    return
                }
                if self.getCurrentViewController() is CallMainVC {
                    guard let userInfo = currentCallUserInfo else { return }
                    currentCallVC?.updateCallType(callKitCallType, userInfo: userInfo, status: .calling)
                    startPlayingStream(currentCallUserInfo?.userID)
                } else {
                    if let currentCallVC = currentCallVC {
                        guard let userInfo = currentCallUserInfo else { return }
                        self.getCurrentViewController()?.present(currentCallVC, animated: true, completion: {
                            currentCallVC.updateCallType(self.callKitCallType, userInfo: userInfo, status: .calling)
                            self.startPlayingStream(self.currentCallUserInfo?.userID)
                        })
                    } else {
                        guard let userInfo = currentCallUserInfo else { return }
                        let callVC: CallMainVC = CallMainVC.loadCallMainVC(callKitCallType, userInfo: userInfo, status: .calling)
                        currentCallVC = callVC
                        getCurrentViewController()?.present(callVC, animated: true) {
                            self.startPlayingStream(userInfo.userID)
                        }
                    }
                }
                if let currentCallVC = currentCallVC,
                    isConnecting {
                    HUDHelper.showNetworkLoading(ZGUIKitLocalizedString("call_page_call_disconnection"), toView: currentCallVC.view)
                }
                    
            } else if currentCallStatus == .wait {
                guard let currentCallUserInfo = currentCallUserInfo else { return }
                if self.getCurrentViewController() is CallMainVC { return }
                let callTipView: CallAcceptTipView = CallAcceptTipView.showTipView(callKitCallType, userInfo: currentCallUserInfo)
                currentTipView = callTipView
                callTipView.delegate = self
            }
        }
        appIsActive = true
        endSystemCall()
    }
    
    @objc func applicationDidEnterBackGround(notification: NSNotification) {
        // Application is back in the foreground
        audioTool.stopPlay()
        if appIsActive && currentCallStatus != .free {
            if let currentCallVC = currentCallVC {
                callKitCallType = currentCallVC.vcType
            }
        }
        appIsActive = false
    }
    
    
    @objc func callKitStart() {
        currentCallStatus = .calling
        callTimeManager.callStart()
        guard let userID = currentCallUserInfo?.userID else {
            currentCallStatus = .free
            return
        }
        let token = delegate?.getRTCToken()
        guard let token = token else {
            currentCallStatus = .free
            return
        }
        ServiceManager.shared.callService.acceptCall(token) { result in
            if result.isSuccess {
                if self.appIsActive {
                    self.endSystemCall()
                    if let callVC = self.currentCallVC {
                        guard let userInfo = self.currentCallUserInfo else { return }
                        callVC.updateCallType(self.callKitCallType, userInfo: userInfo, status: .calling)
                        guard let controller = self.getCurrentViewController() else { return }
                        if controller is CallMainVC {
                            self.currentCallVC?.updateCallType(self.callKitCallType, userInfo: userInfo, status: .calling)
                            self.startPlayingStream(userID)
                        } else {
                            controller.present(callVC, animated: true) {
                                self.startPlayingStream(userID)
                            }
                        }
                    } else {
                        guard let userInfo = self.currentCallUserInfo else { return }
                        let callVC: CallMainVC = CallMainVC.loadCallMainVC(self.callKitCallType, userInfo: userInfo, status: .calling)
                        self.currentCallVC = callVC
                        guard let controller = self.getCurrentViewController() else { return }
                        controller.present(callVC, animated: true) {
                            self.startPlayingStream(userID)
                        }
                    }
                } else {
                    self.startPlayingStream(userID)
                }
            }
        }
    }
        
    @objc func callKitEnd() {
        if appIsActive { return }
        endCall()
    }
    
    @objc func muteSpeaker(notif:NSNotification) {
        let enableMic:Bool = !(notif.userInfo!["isMute"] as? Bool)!
        ServiceManager.shared.deviceService.enableMic(enableMic)
        currentCallVC?.changeBottomButtonDisplayStatus()
    }
    
    func endSystemCall() {
        callKitService?.providerDelegate?.endCall(uuid: myUUID, completion: { uuid in
            
        })
    }
    
    
}

