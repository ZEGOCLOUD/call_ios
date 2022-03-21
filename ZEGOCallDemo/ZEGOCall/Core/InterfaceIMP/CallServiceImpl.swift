//
//  CallServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

class CallServiceImpl: NSObject {
    
    var delegate: CallServiceDelegate?
    
    var status: CallStatus = .free
    
    var callInfo = CallInfo()
    
    private weak var listener = ListenerManager.shared
    
    override init() {
        super.init()
        
        registerListener()
    }
}

extension CallServiceImpl: CallService {
    func callUser(_ userID: String, token: String, type: CallType, callback: RoomCallback?) {
        
        self.status = .outgoing
        
        let callerUserID = ServiceManager.shared.userService.localUserInfo?.userID ?? ""
        let callID = generateCallID(callerUserID)
        
        let command = CallCommand()
        command.userID = callerUserID
        command.invitees = [userID]
        command.callID = callID
        command.type = type
        
        callInfo.callID = callID
        callInfo.inviter = callerUserID
        callInfo.invitees = [userID]
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(let dict):
                //TODO: to add call success logic.
                
                break
            case .failure(let error):
                callResult = .failure(error)
                self.status = .free
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func cancelCall(userID: String, cancelType: CancelType, callback: RoomCallback?) {
        let command = CancelCallCommand()
        command.userID = callInfo.inviter
        command.callID = callInfo.callID
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(let dict):
                self.status = .free
                //TODO: to add call success logic.
                
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func respondCall(_ userID: String, token: String, responseType: ResponseType, callback: RoomCallback?) {
        let command = RespondCallCommand()
        command.userID = ServiceManager.shared.userService.localUserInfo?.userID ?? ""
        command.callID = callInfo.callID
        command.type = responseType
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(let dict):
                
                //TODO: to add respond call success logic.
                break
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func endCall(_ callback: RoomCallback?) {
        let command = EndCallCommand()
        command.userID = ServiceManager.shared.userService.localUserInfo?.userID ?? ""
        command.callID = callInfo.callID
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                self.status = .free
                //TODO: add end call logic.
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
}

extension CallServiceImpl {
    private func generateCallID(_ userID: String) -> String {
        //TODO: generate call id
        return ""
    }
    
    private func registerListener() {
        
        listener?.registerListener(self, for: Notify_Call_Invited, callback: { result in
            
        })
        
        listener?.registerListener(self, for: Notify_Call_Canceled, callback: { result in
            
        })
        
        listener?.registerListener(self, for: Notify_Call_Response, callback: { result in
            
        })
        
        listener?.registerListener(self, for: Notify_Call_End, callback: { result in
            
        })
        
        listener?.registerListener(self, for: Notify_Call_Timeout, callback: { result in
            
        })
    }
}
