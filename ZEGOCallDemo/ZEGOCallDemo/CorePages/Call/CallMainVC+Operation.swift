//
//  CallMainVC+Operation.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/14.
//

import Foundation
import ZegoExpressEngine

extension CallMainVC: CallActionDelegate {
    func callhandUp(_ callView: CallBaseView) {
        if let userID = self.callUser?.userID {
            if self.statusType == .calling {
                RoomManager.shared.userService.endCall() { result in
                    switch result {
                    case .success():
                        CallBusiness.shared.audioPlayer?.stop()
                        CallBusiness.shared.currentCallStatus = .free
                        self.changeCallStatusText(.completed)
                        self.callDelayDismiss()
                    case .failure(let error):
                        let message = String(format: ZGLocalizedString("end_call_failed"), error.code)
                        TipView.showWarn(message)
                    }
                }
            } else {
                cancelCall(userID, callType: self.vcType)
            }
        }
    }
    
    func cancelCall(_ userID: String, callType: CallType, isTimeout: Bool = false) {
        var cancelType: CancelType = .intent
        if isTimeout { cancelType = .timeout}
        RoomManager.shared.userService.cancelCall(userID: userID, cancelType: cancelType) { result in
            switch result {
            case .success():
                CallBusiness.shared.audioPlayer?.stop()
                CallBusiness.shared.currentCallStatus = .free
                if isTimeout {
                    self.changeCallStatusText(.miss)
                } else {
                    self.changeCallStatusText(.canceled)
                }
                self.callDelayDismiss()
            case .failure(let error):
                let message = String(format: ZGLocalizedString("cancel_call_failed"), error.code)
                TipView.showWarn(message)
            }
        }
    }
    
    func callAccept(_ callView: CallBaseView) {
        updateCallType(self.vcType, userInfo: self.callUser ?? UserInfo(), status: .calling)
        if let userID = self.callUser?.userID {
            let token = AppToken.getToken(withUserID: localUserID)
            guard let token = token else { return }
            RoomManager.shared.userService.respondCall(userID, token:token, responseType: .accept) { result in
                CallBusiness.shared.audioPlayer?.stop()
                if result.isSuccess {
                    CallBusiness.shared.currentCallStatus = .calling
                    ZegoExpressEngine.shared().useFrontCamera(true)
                    self.startPlayingStream(userID)
                } else {
                    CallBusiness.shared.currentCallStatus = .free
                    self.changeCallStatusText(.decline)
                    self.callDelayDismiss()
                }
            }
        }
    }
    
    func startPlayingStream(_ userID: String) {
        if let userRoomInfo = RoomManager.shared.userService.localUserRoomInfo {
            if vcType == .voice {
                RoomManager.shared.userService.enableMic(userRoomInfo.mic, callback: nil)
                guard let callUser = callUser else { return }
                RoomManager.shared.userService.startPlaying(callUser.userID, streamView: nil)
            } else {
                RoomManager.shared.userService.enableMic(userRoomInfo.mic, callback: nil)
                RoomManager.shared.userService.enableCamera(userRoomInfo.camera, callback: nil)
                let mainUserID = mainStreamUserID != nil ? mainStreamUserID : RoomManager.shared.userService.localUserInfo?.userID
                RoomManager.shared.userService.startPlaying(mainUserID, streamView: mainPreviewView)
                
                let previewUserID = streamUserID != nil ? streamUserID : userID
                RoomManager.shared.userService.startPlaying(previewUserID, streamView: previewView)
            }
            RoomManager.shared.userService.enableSpeaker(RoomManager.shared.userService.localUserRoomInfo?.voice ?? false)
        }
    }
    
    func callDecline(_ callView: CallBaseView) {
        if let userID = self.callUser?.userID {
            let token = AppToken.getToken(withUserID: localUserID)
            guard let token = token else { return }
            RoomManager.shared.userService.respondCall(userID, token: token ,responseType: .decline) { result in
                if result.isSuccess {
                    CallBusiness.shared.audioPlayer?.stop()
                    CallBusiness.shared.currentCallStatus = .free
                    self.changeCallStatusText(.decline)
                    self.callDelayDismiss()
                }
            }
        }
    }
    
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool) {
        
        RoomManager.shared.userService.enableMic(isOpen, callback: nil)
    }
    
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        RoomManager.shared.userService.enableSpeaker(isOpen)
    }
    
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        RoomManager.shared.userService.enableCamera(isOpen, callback: nil)
    }
    
    func callFlipCamera(_ callView: CallBaseView) {
        self.useFrontCamera = !self.useFrontCamera
        RoomManager.shared.userService.useFrontCamera(self.useFrontCamera)
    }
    
    func callDelayDismiss() {
        CallBusiness.shared.currentCallStatus = .free
        UIApplication.shared.isIdleTimerDisabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.resetTime()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
