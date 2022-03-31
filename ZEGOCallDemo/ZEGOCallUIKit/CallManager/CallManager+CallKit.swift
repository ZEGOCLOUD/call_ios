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
                if self.getCurrentViewController() is CallMainVC {
                    guard let userInfo = currentCallUserInfo else { return }
                    currentCallVC?.updateCallType(callKitCallType, userInfo: userInfo, status: .calling)
                    startPlayingStream(currentCallUserInfo?.userID)
                } else {
                    if let currentCallVC = currentCallVC {
                        guard let userInfo = currentCallUserInfo else { return }
                        self.getCurrentViewController()?.present(currentCallVC, animated: true, completion: {
                            currentCallVC.updateCallType(self.callKitCallType, userInfo: userInfo, status: .calling)
                            //currentCallVC.callTime = self.startCallTime
                            self.startPlayingStream(self.currentCallUserInfo?.userID)
                        })
                    } else {
                        guard let userInfo = currentCallUserInfo else { return }
                        let callVC: CallMainVC = CallMainVC.loadCallMainVC(callKitCallType, userInfo: userInfo, status: .calling)
                        currentCallVC = callVC
                        //callVC.callTime = startCallTime
                        getCurrentViewController()?.present(callVC, animated: true) {
                            self.startPlayingStream(userInfo.userID)
                        }
                    }
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
        audioPlayer?.stop()
        if appIsActive && currentCallStatus != .free {
            if let currentCallVC = currentCallVC {
                callKitCallType = currentCallVC.vcType
            }
        }
        appIsActive = false
    }
    
    
    @objc func callKitStart() {
//        if !isConnected {
//            if let userID = currentCallUserInfo?.userID {
//                endCall(userID)
//            }
//            return
//        }
        currentCallStatus = .calling
        callTimeManager.callStart()
        guard let userID = currentCallUserInfo?.userID,
              let token = token else { return }
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
        guard let userID = currentCallUserInfo?.userID else { return }
        endCall(userID)
//        if currentCallStatus == .calling {
//            endCall(currentCallUserInfo?.userID)
//            ServiceManager.shared.callService.endCall() { result in
//                switch result {
//                case .success():
//                    self.currentCallStatus = .free
//                    self.currentCallUserInfo = nil
//                    HUDHelper.showMessage(message: "Complete")
//                case .failure(let error):
//                    //HUDHelper.showMessage(message: "")
//                    break
//                }
//            }
//        } else {
//            endCall(currentCallUserInfo?.userID ?? "")
//            currentCallStatus = .free
//            currentCallUserInfo = nil
//        }
    }
    
    @objc func muteSpeaker(notif:NSNotification) {
        guard let localUserInfo = ServiceManager.shared.userService.localUserInfo else { return }
        localUserInfo.mic = !(notif.userInfo!["isMute"] as? Bool)!
        ServiceManager.shared.deviceService.enableMic(localUserInfo.mic)
        currentCallVC?.changeBottomButtonDisplayStatus()
    }
    
    func endSystemCall() {
        callKitService?.providerDelegate?.endCall(uuid: myUUID, completion: { uuid in
            
        })
    }
    
    
}

