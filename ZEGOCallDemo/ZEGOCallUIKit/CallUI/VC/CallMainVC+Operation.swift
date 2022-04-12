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
        guard let callUser = otherUser else { return }
        CallManager.shared.acceptCall(callUser, callType: vcType, presentVC: false)
    }
    
    func callhandUp(_ callView: CallBaseView) {
        if self.statusType == .calling {
            CallManager.shared.endCall()
            self.changeCallStatusText(.completed)
            self.callDelayDismiss()
        } else {
            CallManager.shared.cancelCall()
        }
    }
    
    func callDecline(_ callView: CallBaseView) {
        changeCallStatusText(.decline)
        callDelayDismiss()
        CallManager.shared.declineCall()
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
        CallManager.shared.currentCallVC = nil
    }
}
