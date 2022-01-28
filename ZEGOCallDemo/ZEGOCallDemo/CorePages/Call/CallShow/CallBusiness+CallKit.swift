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
        if appIsActive && currentCallStatus != .free {
            if let currentCallVC = currentCallVC {
                callKitCallType = currentCallVC.vcType
            }
        }
        appIsActive = false
        audioPlayer?.stop()
    }
    
    
    @objc func callKitStart() {
        currentCallStatus = .calling
        if let userID = currentCallUserInfo?.userID {
            let rtcToken = AppToken.getRtcToken(withRoomID: userID)
            guard let rtcToken = rtcToken else { return }
            RoomManager.shared.userService.responseCall(userID, token: rtcToken, responseType: .accept) { result in
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
                        let streamID = String.getStreamID(userID, roomID: RoomManager.shared.userService.roomService.roomInfo.roomID)
                        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
                    }
                case .failure(_):
                    break
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
            endCall(currentCallUserInfo?.userID ?? "", callType: callKitCallType)
            currentCallStatus = .free
            currentCallUserInfo = nil
        }
    }
    
    @objc func muteSpeaker() {
        if let localUserInfo = RoomManager.shared.userService.localUserRoomInfo {
            let mic = localUserInfo.mic
            localUserInfo.mic = !mic
            RoomManager.shared.userService.enableMic(localUserInfo.mic, callback: nil)
        }
    }
    
    func endSystemCall() {
        appDelegate.providerDelegate?.endCall(uuids: [myUUID], completion: { uuid in
            
        })
    }
    
    
}

