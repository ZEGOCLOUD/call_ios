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
                ServiceManager.shared.callService.endCall(nil)
                CallManager.shared.audioPlayer?.stop()
                CallManager.shared.currentCallStatus = .free
                self.changeCallStatusText(.completed)
                self.callDelayDismiss()
            } else {
                cancelCall(userID, callType: self.vcType)
            }
        }
    }
    
    func cancelCall(_ userID: String, callType: CallType, isTimeout: Bool = false) {
        ServiceManager.shared.callService.cancelCall(userID: userID, callback: nil)
        CallManager.shared.audioPlayer?.stop()
        CallManager.shared.currentCallStatus = .free
        if isTimeout {
            self.changeCallStatusText(.miss)
        } else {
            self.changeCallStatusText(.canceled)
        }
    }
    
    func callAccept(_ callView: CallBaseView) {
        updateCallType(self.vcType, userInfo: self.callUser ?? UserInfo(), status: .calling)
        if let userID = self.callUser?.userID {
            let rtcToken = AppToken.getRtcToken(withRoomID: userID)
            guard let rtcToken = rtcToken else { return }
            ServiceManager.shared.callService.acceptCall(rtcToken) { result in
                CallManager.shared.audioPlayer?.stop()
                if result.isSuccess {
                    CallManager.shared.currentCallStatus = .calling
                    CallManager.shared.callTimeManager.callStart()
                    ZegoExpressEngine.shared().useFrontCamera(true)
                    self.startPlayingStream(userID)
                } else {
                    CallManager.shared.currentCallStatus = .free
                    self.changeCallStatusText(.decline)
                    self.callDelayDismiss()
                }
            }
        }
    }
    
    func startPlayingStream(_ userID: String) {
        if let userRoomInfo = ServiceManager.shared.userService.localUserInfo {
            if vcType == .voice {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
                guard let callUser = callUser else { return }
                ServiceManager.shared.streamService.startPlaying(callUser.userID, streamView: nil)
            } else {
                ServiceManager.shared.deviceService.enableMic(userRoomInfo.mic)
                ServiceManager.shared.deviceService.enableCamera(userRoomInfo.camera)
                let mainUserID = mainStreamUserID != nil ? mainStreamUserID : ServiceManager.shared.userService.localUserInfo?.userID
                ServiceManager.shared.streamService.startPlaying(mainUserID, streamView: mainPreviewView)
                
                let previewUserID = streamUserID != nil ? streamUserID : userID
                ServiceManager.shared.streamService.startPlaying(previewUserID, streamView: previewView)
            }
            ServiceManager.shared.deviceService.enableSpeaker(false)
        }
    }
    
    func callDecline(_ callView: CallBaseView) {
        if let userID = self.callUser?.userID {
            ServiceManager.shared.callService.declineCall(userID, type: .decline, callback: nil)
            CallManager.shared.audioPlayer?.stop()
            CallManager.shared.currentCallStatus = .free
            self.changeCallStatusText(.decline)
            self.callDelayDismiss()
        }
    }
    
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableMic(isOpen)
    }
    
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableSpeaker(isOpen)
    }
    
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableCamera(isOpen)
    }
    
    func callFlipCamera(_ callView: CallBaseView) {
        self.useFrontCamera = !self.useFrontCamera
        ServiceManager.shared.deviceService.useFrontCamera(self.useFrontCamera)
    }
    
    func callDelayDismiss() {
        CallManager.shared.currentCallStatus = .free
        UIApplication.shared.isIdleTimerDisabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.resetTime()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
