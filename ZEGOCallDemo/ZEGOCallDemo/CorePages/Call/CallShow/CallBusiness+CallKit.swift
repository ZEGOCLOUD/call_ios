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
                        self.getCurrentViewController()?.present(currentCallVC, animated: true, completion: {
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
            } else if currentCallStatus == .wait {
                guard let currentCallUserInfo = currentCallUserInfo else { return }
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
        if appIsActive && currentCallStatus != .free {
            if let currentCallVC = currentCallVC {
                callKitCallType = currentCallVC.vcType
            }
        }
        appIsActive = false
    }
    
    
    @objc func callKitStart() {
        currentCallStatus = .calling
        if let userID = currentCallUserInfo?.userID {
            RoomManager.shared.userService.responseCall(userID, callType: callKitCallType,responseType: .accept) { result in
                switch result {
                case .success():
                    if self.appIsActive {
                        if let callVC = self.currentCallVC {
                            guard let userInfo = self.currentCallUserInfo else { return }
                            callVC.updateCallType(self.callKitCallType, userInfo: userInfo, status: .calling)
                            if let controller = self.getCurrentViewController() {
                                controller.present(callVC, animated: true) {
                                    self.startPlayingStream(userID)
                                }
                            }
                        } else {
                            guard let userInfo = self.currentCallUserInfo else { return }
                            let callVC: CallMainVC = CallMainVC.loadCallMainVC(self.callKitCallType, userInfo: userInfo, status: .calling)
                            self.currentCallVC = callVC
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
            guard let userID = currentCallUserInfo?.userID else { return }
            RoomManager.shared.userService.endCall(userID) { result in
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
            let voice = localUserInfo.voice ?? false
            localUserInfo.voice = !voice
            ZegoExpressEngine.shared().muteSpeaker(voice)
        }
    }
    
    func endSystemCall() {
        appDelegate.providerDelegate?.endCall(uuids: [myUUID], completion: { uuid in
            
        })
    }
    
    
}

