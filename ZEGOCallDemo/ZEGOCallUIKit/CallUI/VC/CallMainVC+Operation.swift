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
                ServiceManager.shared.callService.endCall() { result in
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
        ServiceManager.shared.callService.cancelCall(userID: userID, cancelType: .intent) { result in
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
            let rtcToken = AppToken.getRtcToken(withRoomID: userID)
            guard let rtcToken = rtcToken else { return }
            ServiceManager.shared.callService.respondCall(userID, token:rtcToken, responseType: .accept) { result in
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
        if let userRoomInfo = ServiceManager.shared.userService.localUserInfo {
            if vcType == .voice {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
                guard let callUser = callUser else { return }
                ServiceManager.shared.streamService.startPlaying(callUser.userID, streamView: nil)
            } else {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic, callback: nil)
                ServiceManager.shared.deviceService.enableCamera(userRoomInfo.camera, callback: nil)
                let mainUserID = mainStreamUserID != nil ? mainStreamUserID : ServiceManager.shared.userService.localUserInfo?.userID
                ServiceManager.shared.streamService.startPlaying(mainUserID, streamView: mainPreviewView)
                
                let previewUserID = streamUserID != nil ? streamUserID : userID
                ServiceManager.shared.streamService.startPlaying(previewUserID, streamView: previewView)
            }
            ServiceManager.shared.deviceService.enableSpeaker(ServiceManager.shared.userService.localUserInfo?.voice ?? false)
        }
    }
    
    func callDecline(_ callView: CallBaseView) {
        if let userID = self.callUser?.userID {
            let rtcToken = AppToken.getRtcToken(withRoomID: userID)
            guard let rtcToken = rtcToken else { return }
            ServiceManager.shared.callService.respondCall(userID, token: rtcToken ,responseType: .decline) { result in
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
        
        ServiceManager.shared.deviceService.enableMic(isOpen, callback: nil)
    }
    
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableSpeaker(isOpen)
    }
    
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableCamera(isOpen, callback: nil)
    }
    
    func callFlipCamera(_ callView: CallBaseView) {
        self.useFrontCamera = !self.useFrontCamera
        ServiceManager.shared.deviceService.useFrontCamera(self.useFrontCamera)
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
