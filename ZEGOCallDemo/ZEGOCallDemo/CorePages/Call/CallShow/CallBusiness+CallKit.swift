//
//  CallBusiness+CallKit.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation
import ZegoExpressEngine

extension CallBusiness {
    
    @objc func callKitStart() {
        if let userID = callKitUserInfo?.userID {
            RoomManager.shared.userService.responseCall(userID, callType: callKitCallType,responseType: .accept) { result in
                switch result {
                case .success():
                    //self.startPlaying(userID, streamView: nil, type: self.callKitCallType)
                    if self.callKitCallType == .video {
                        let streamID = String.getStreamID(userID, roomID: RoomManager.shared.userService.roomService.roomInfo.roomID, isVideo: true)
                        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
                    } else {
                        let streamID = String.getStreamID(userID, roomID: RoomManager.shared.userService.roomService.roomInfo.roomID)
                        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
                    }
                    
                    //self.startPlayingStream(userID)
                    
    //                    let callVC: CallMainVC = CallMainVC.loadCallMainVC(self.callKitCallType, userInfo: self.callKitUserInfo ?? UserInfo(), status: .calling)
    //                    self.currentCallVC = callVC
    //                    if let controller = self.getCurrentViewController() {
    //                        controller.present(callVC, animated: true) {
    //                            self.startPlayingStream(userID)
    //                        }
    //                    }
                    let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
    //                    if let uuid = UUID(uuidString: deviceID) {
    //                        self.appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuuid in
    //
    //                        })
    //                    }
                case .failure(_):
                    break
                }
                
            }
        }
        
    }
        
    @objc func callKitEnd() {
        
    }
    
    @objc func muteSpeaker() {
        if let localUserInfo = RoomManager.shared.userService.localUserInfo {
            localUserInfo.voice = !localUserInfo.voice
            ZegoExpressEngine.shared().muteSpeaker(localUserInfo.voice)
        }
    }
    
}

