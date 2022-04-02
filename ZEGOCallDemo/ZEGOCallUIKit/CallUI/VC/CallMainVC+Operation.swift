//
//  CallMainVC+Operation.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/14.
//

import Foundation
import ZegoExpressEngine

extension CallMainVC: CallActionDelegate {
    func callAccept(_ callView: CallBaseView) {
        guard let callUser = callUser else { return }
        CallManager.shared.acceptCall(callUser, callType: vcType, presentVC: false)
    }
    
    func callhandUp(_ callView: CallBaseView) {
        if let userID = self.callUser?.userID {
            if self.statusType == .calling {
                CallManager.shared.endCall(userID)
                self.changeCallStatusText(.completed)
                self.callDelayDismiss()
            } else {
                CallManager.shared.cancelCall(userID, callType: self.vcType)
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
        changeCallStatusText(.decline)
        callDelayDismiss()
        guard let userID = self.callUser?.userID else { return }
        CallManager.shared.declineCall(userID, type: .decline)
    }
    
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableMic(isOpen)
    }
    
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableSpeaker(isOpen)
    }
    
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableCamera(isOpen)
        userRoomInfoUpdate(localUserInfo)
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
