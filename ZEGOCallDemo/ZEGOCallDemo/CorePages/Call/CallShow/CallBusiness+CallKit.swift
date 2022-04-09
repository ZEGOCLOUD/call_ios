//
//  CallBusiness+CallKit.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation
import ZegoExpressEngine
import UIKit

extension CallBusiness {
    
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
                            currentCallVC.callTime = self.startCallTime
                            self.startPlayingStream(self.currentCallUserInfo?.userID)
                        })
                    } else {
                        guard let userInfo = currentCallUserInfo else { return }
                        let callVC: CallMainVC = CallMainVC.loadCallMainVC(callKitCallType, userInfo: userInfo, status: .calling)
                        currentCallVC = callVC
                        callVC.callTime = startCallTime
                        getCurrentViewController()?.present(callVC, animated: true) {
                            self.startPlayingStream(userInfo.userID)
                        }
                    }
                }
            } else if currentCallStatus == .wait {
                guard let currentCallUserInfo = currentCallUserInfo else { return }
                let currentTimeStamp = Int(Date().timeIntervalSince1970)
                if startTimeIdentify > 0 && currentTimeStamp - startTimeIdentify > 60 {
                    CallAcceptTipView.dismiss()
                    tipViewDeclineCall(currentCallUserInfo, callType: callKitCallType)
                    startTimeIdentify = 0
                } else {
                    if self.getCurrentViewController() is CallMainVC { return }
                    let callTipView: CallAcceptTipView = CallAcceptTipView.showTipView(callKitCallType, userInfo: currentCallUserInfo)
                    currentTipView = callTipView
                    callTipView.delegate = self
                }
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
        if !isConnected {
            if let userID = currentCallUserInfo?.userID {
                endCall(userID)
            }
            return
        }
        currentCallStatus = .calling
        if let userID = currentCallUserInfo?.userID {
            TokenManager.shared.getToken(localUserID) { result in
                if result.isSuccess {
                    let token: String? = result.success
                    guard let token = token else {
                        print("token is nil")
                        return
                    }
                    RoomManager.shared.userService.respondCall(userID, token: token, responseType: .accept) { result in
                        switch result {
                        case .success():
                            self.startCallTime = Int(Date().timeIntervalSince1970)
                            if self.appIsActive {
                                if let callVC = self.currentCallVC {
                                    guard let userInfo = self.currentCallUserInfo else { return }
                                    callVC.updateCallType(self.callKitCallType, userInfo: userInfo, status: .calling)
                                    callVC.callTime = self.startCallTime
                                    if let controller = self.getCurrentViewController() {
                                        if controller is CallMainVC {
                                            self.currentCallVC?.updateCallType(self.callKitCallType, userInfo: userInfo, status: .calling)
                                            self.startPlayingStream(userID)
                                        } else {
                                            controller.present(callVC, animated: true) {
                                                self.startPlayingStream(userID)
                                            }
                                        }
                                    }
                                } else {
                                    guard let userInfo = self.currentCallUserInfo else { return }
                                    let callVC: CallMainVC = CallMainVC.loadCallMainVC(self.callKitCallType, userInfo: userInfo, status: .calling)
                                    self.currentCallVC = callVC
                                    callVC.callTime = self.startCallTime
                                    if let controller = self.getCurrentViewController() {
                                        controller.present(callVC, animated: true) {
                                            self.startPlayingStream(userID)
                                        }
                                    }
                                }
                                self.endSystemCall()
                            } else {
                                self.startPlayingStream(userID)
                            }
                        case .failure(_):
                            break
                        }
                    }
                    
                } else {
                    HUDHelper.showMessage(message: "get token fail")
                }
            }
        }
        
    }
        
    @objc func callKitEnd() {
        if appIsActive { return }
        if currentCallStatus == .calling {
            RoomManager.shared.userService.endCall() { result in
                switch result {
                case .success():
                    self.currentCallStatus = .free
                    self.currentCallUserInfo = nil
                    HUDHelper.showMessage(message: "Complete")
                case .failure(let error):
                    //HUDHelper.showMessage(message: "")
                    break
                }
            }
        } else {
            endCall(currentCallUserInfo?.userID ?? "")
            currentCallStatus = .free
            currentCallUserInfo = nil
        }
    }
    
    @objc func muteSpeaker(notif:NSNotification) {
        if let localUserInfo = RoomManager.shared.userService.localUserRoomInfo {
            localUserInfo.mic = !(notif.userInfo!["isMute"] as? Bool)!
            RoomManager.shared.userService.enableMic(localUserInfo.mic, callback: nil)
            currentCallVC?.changeBottomButtonDisplayStatus()
        }
    }
    
    func endSystemCall() {
        appDelegate.providerDelegate?.endCall(uuid: myUUID, completion: { uuid in
            
        })
    }
    
    
}

