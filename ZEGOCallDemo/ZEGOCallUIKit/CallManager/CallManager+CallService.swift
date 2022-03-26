//
//  CallManager+CallService.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/19.
//

import UIKit

extension CallManager: CallServiceDelegate {
    
    func onReceiveCallInvited(_ userInfo: UserInfo, type: CallType) {
        delegate?.onReceiveCallInvite(userInfo, type: type)
        if currentCallStatus == .calling || currentCallStatus == .wait || currentCallStatus == .waitAccept {
            guard let userID = userInfo.userID else { return }
            declineCall(userID)
            return
        }
        startTimeIdentify = Int(Date().timeIntervalSince1970)
        currentCallStatus = .wait
        currentCallUserInfo = userInfo
        callKitCallType = type
        if UIApplication.shared.applicationState != .background {
            let callTipView: CallAcceptTipView = CallAcceptTipView.showTipView(type, userInfo: userInfo)
            currentTipView = callTipView
            callTipView.delegate = self
            audioPlayer?.play()
        } else {
            if !enableCallKit { return }
            let uuid = UUID()
            myUUID = uuid
            callKitService?.reportInComingCall(uuid: uuid, handle: "", hasVideo: type == .video, completion: nil)
        }
    }
    
    func onReceiveCallCanceled(_ userInfo: UserInfo) {
        delegate?.onReceiveCallCanceled(userInfo)
        if (currentCallStatus == .calling || currentCallStatus == .wait) && userInfo.userID != currentCallUserInfo?.userID {
            return
        }
        
        currentCallStatus = .free
        currentCallUserInfo = nil
        endSystemCall()
        audioPlayer?.stop()
        CallAcceptTipView.dismiss()
        guard let currentCallVC = currentCallVC else { return }
        //TODO: to handle canceled call
//        if type == .intent {
//            currentCallVC.changeCallStatusText(.canceled)
//        } else {
//            currentCallVC.changeCallStatusText(.miss)
//        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.shared.isIdleTimerDisabled = false
            currentCallVC.statusType = .completed
            currentCallVC.resetTime()
            currentCallVC.dismiss(animated: true, completion: nil)
        }
    }
    func onReceiveCallAccepted(_ userInfo: UserInfo) {
        delegate?.onReceiveCallAccepted(userInfo)
        guard let vc = self.currentCallVC else { return }
        if !appIsActive {
            if let userID = userInfo.userID {
                if currentCallStatus == .waitAccept {
                    endCall(userID)
                    closeCallVC()
                }
            }
            return
        }
        currentCallUserInfo = userInfo
        currentCallStatus = .calling
        vc.updateCallType(vc.vcType, userInfo: userInfo, status: .calling)
        callTimeManager.callStart()
        startPlayingStream(userInfo.userID)
    }
    func onReceiveCallDeclined(_ userInfo: UserInfo, type: DeclineType) {
        delegate?.onReceiveCallDeclined(userInfo, type: type)
        currentCallUserInfo = nil
        currentCallStatus = .free
        ServiceManager.shared.callService.endCall() { result in
            if result.isSuccess {
                let statusType: CallStatusType = type == .busy ? .busy : .decline
                self.currentCallVC?.changeCallStatusText(statusType)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.closeCallVC()
                }
            }
        }
    }
    
    func onReceiveCallEnded() {
        delegate?.onReceivedCallEnded()
        audioPlayer?.stop()
        if currentCallStatus != .calling {
            currentCallVC?.changeCallStatusText(.completed,showHud: false)
        } else {
            currentCallVC?.changeCallStatusText(.completed,showHud: true)
        }
        currentCallUserInfo = nil
        currentCallStatus = .free
        otherUserRoomInfo = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.endSystemCall()
            self.closeCallVC()
        }
    }
    
    func onReceiveCallTimeout(_ type: CallTimeoutType, info: UserInfo) {
        delegate?.onReceiveCallTimeout(type, info: info)
        switch type {
        case .connecting:
            if currentCallStatus == .wait {
                CallAcceptTipView.dismiss()
                self.currentCallStatus = .free
                self.currentCallUserInfo = nil
                self.audioPlayer?.stop()
                self.endSystemCall()
            } else if currentCallStatus == .waitAccept {
                minmizedManager.dismissCallMinView()
                guard let vc = currentCallVC else { return }
                vc.cancelCall(vc.callUser?.userID ?? "", callType: vc.vcType, isTimeout: true)
                vc.changeCallStatusText(.miss)
                vc.callDelayDismiss()
            }
        case .calling:
            break
        }
    }
}
