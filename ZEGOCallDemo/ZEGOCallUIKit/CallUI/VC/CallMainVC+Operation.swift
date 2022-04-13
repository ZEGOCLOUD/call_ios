//
//  CallMainVC+Operation.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/14.
//

import Foundation
import ZegoExpressEngine

extension CallMainVC: CallActionDelegate {
    /// Answer the call
    func callAccept(_ callView: CallBaseView) {
        guard let callUser = otherUser else { return }
        CallManager.shared.acceptCall(callUser, callType: vcType, presentVC: false)
    }
    
    /// Hang up the call
    func callhandUp(_ callView: CallBaseView) {
        if self.statusType == .calling {
            CallManager.shared.endCall()
            self.changeCallStatusText(.completed)
            self.callDelayDismiss()
        } else {
            CallManager.shared.cancelCall()
        }
    }
    
    /// Decline the call
    func callDecline(_ callView: CallBaseView) {
        changeCallStatusText(.decline)
        callDelayDismiss()
        CallManager.shared.declineCall()
    }
    
    /// open/close mic
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableMic(isOpen)
    }
    
    /// open/close Speaker
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableSpeaker(isOpen)
    }
    
    /// open/close camera
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        ServiceManager.shared.deviceService.enableCamera(isOpen)
        userRoomInfoUpdate(localUserInfo)
    }
    
    /// Flip camera
    func callFlipCamera(_ callView: CallBaseView) {
        self.useFrontCamera = !self.useFrontCamera
        ServiceManager.shared.deviceService.useFrontCamera(self.useFrontCamera)
    }
    
    /// Delay close call page
    func callDelayDismiss() {
        CallManager.shared.currentCallStatus = .free
        UIApplication.shared.isIdleTimerDisabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.resetTime()
            self.dismiss(animated: true, completion: nil)
        }
        CallManager.shared.currentCallVC = nil
    }
}
