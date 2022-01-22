//
//  CallBusiness+CallKit.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation
import ZegoExpressEngine

extension CallBusiness {
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        // Application is back in the foreground
        if !appIsActive && currentCallStatus == .calling {
            if self.getCurrentViewController() is CallMainVC {
                self.startPlayingStream(currentCallUserInfo?.userID)
            } else {
                if let currentCallVC = self.currentCallVC {
                    self.getCurrentViewController()?.present(currentCallVC, animated: true, completion: {
                        self.startPlayingStream(self.currentCallUserInfo?.userID)
                    })
                } else {
                    guard let userInfo = self.currentCallUserInfo else { return }
                    let callVC: CallMainVC = CallMainVC.loadCallMainVC(self.callKitCallType, userInfo: userInfo, status: .calling)
                    self.currentCallVC = callVC
                    getCurrentViewController()?.present(callVC, animated: true) {
                        self.startPlayingStream(userInfo.userID)
                    }
                }
            }
        }
        appIsActive = true
    }
    
    @objc func applicationDidEnterBackGround(notification: NSNotification) {
        // Application is back in the foreground
        if appIsActive && currentCallStatus != .free {
            self.appDelegate.providerDelegate?.call(handle: "")
        }
        appIsActive = false
    }
    
    
    @objc func callKitStart() {
        currentCallStatus = .calling
        if let userID = currentCallUserInfo?.userID {
            RoomManager.shared.userService.responseCall(userID, callType: callKitCallType,responseType: .accept) { result in
                switch result {
                case .success():
                    //self.startPlaying(userID, streamView: nil, type: self.callKitCallType)
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
                        let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
                        if let uuid = UUID(uuidString: deviceID) {
                            self.appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuuid in
    
                            })
                        }
                    } else {
                        if self.callKitCallType == .video {
                            let streamID = String.getStreamID(userID, roomID: RoomManager.shared.userService.roomService.roomInfo.roomID, isVideo: true)
                            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
                        } else {
                            let streamID = String.getStreamID(userID, roomID: RoomManager.shared.userService.roomService.roomInfo.roomID)
                            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
                        }
                    }
                case .failure(_):
                    break
                }
                
            }
        }
        
    }
        
    @objc func callKitEnd() {
        if currentCallStatus == .calling {
            guard let userID = currentCallUserInfo?.userID else { return }
            RoomManager.shared.userService.endCall(userID) { result in
                switch result {
                case .success():
                    self.currentCallStatus = .free
                    self.currentCallUserInfo = nil
                    HUDHelper.showMessage(message: "Complete")
                    self.appDelegate.providerDelegate?.endCall(uuids: [UUID()], completion: { uuid in
                        
                    })
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
        if let localUserInfo = RoomManager.shared.userService.localUserInfo {
            localUserInfo.voice = !localUserInfo.voice
            ZegoExpressEngine.shared().muteSpeaker(localUserInfo.voice)
        }
    }
    
    
}

