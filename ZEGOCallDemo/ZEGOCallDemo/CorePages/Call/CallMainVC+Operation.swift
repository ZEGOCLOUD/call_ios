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
                RoomManager.shared.userService.endCall(userID) { result in
                    switch result {
                    case .success():
                        CallBusiness.shared.currentCallStatus = .free
                        HUDHelper.showMessage(message: "Complete")
                        let deviceID: String = UIDevice.current.identifierForVendor!.uuidString
                        if let uuid = UUID(uuidString: deviceID) {
                            self.appDelegate.providerDelegate?.endCall(uuids: [uuid], completion: { uuid in
                                
                            })
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.dismiss(animated: true, completion: nil)
                        }
                    case .failure(let error):
                        //HUDHelper.showMessage(message: "")
                        break
                    }
                }
            } else {
                cancelCall(userID, callType: self.vcType)
            }
        }
    }
    
    func cancelCall(_ userID: String, callType: CallType, isTimeout: Bool = false) {
        RoomManager.shared.userService.cancelCallToUser(userID: userID, callType: self.vcType) { result in
            switch result {
            case .success():
                CallBusiness.shared.currentCallStatus = .free
                if isTimeout {
                    HUDHelper.showMessage(message: "Miss")
                } else {
                    HUDHelper.showMessage(message: "Canceled")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.dismiss(animated: true, completion: nil)
                }
            case .failure(let error):
                //HUDHelper.showMessage(message: "")
                break
            }
        }
    }
    
    func callAccept(_ callView: CallBaseView) {
        updateCallType(self.vcType, userInfo: self.callUser ?? UserInfo(), status: .calling)
        if let userID = self.callUser?.userID {
            RoomManager.shared.userService.responseCall(userID, callType: self.vcType, responseType: .accept) { result in
                
            }
        }
    }
    
    func callDecline(_ callView: CallBaseView) {
        if let userID = self.callUser?.userID {
            RoomManager.shared.userService.responseCall(userID, callType: self.vcType, responseType: .reject) { result in
                
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool) {
        RoomManager.shared.userService.micOperation(isOpen, callback: nil)
    }
    
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        ZegoExpressEngine.shared().muteSpeaker(isOpen)
    }
    
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        RoomManager.shared.userService.cameraOpen(isOpen, callback: nil)
    }
    
    func callFlipCamera(_ callView: CallBaseView) {
        self.useFrontCamera = !self.useFrontCamera
        ZegoExpressEngine.shared().useFrontCamera(self.useFrontCamera)
    }
}
