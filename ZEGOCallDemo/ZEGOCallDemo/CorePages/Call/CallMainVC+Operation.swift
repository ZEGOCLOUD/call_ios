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
        if let userID = RoomManager.shared.userService.localUserInfo?.userID {
            RoomManager.shared.userService.endCall(userID, callback: nil)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func callAccept(_ callView: CallBaseView) {
        updateCallType(self.vcType, userInfo: self.callUser ?? UserInfo(), status: .calling)
        if let userID = RoomManager.shared.userService.localUserInfo?.userID {
            RoomManager.shared.userService.responseCall(userID, responseType: .accept) { result in
                
            }
        }
    }
    
    func callDecline(_ callView: CallBaseView) {
        if let userID = RoomManager.shared.userService.localUserInfo?.userID {
            RoomManager.shared.userService.responseCall(userID, responseType: .reject) { result in
                
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool) {
        RoomManager.shared.userService.micOperation(isOpen) { result in
            
        }
    }
    
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        
    }
    
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        RoomManager.shared.userService.cameraOpen(isOpen) { result in
            
        }
    }
    
    func callFlipCamera(_ callView: CallBaseView) {
        self.useFrontCamera = !self.useFrontCamera
        ZegoExpressEngine.shared().useFrontCamera(self.useFrontCamera)
    }
}
