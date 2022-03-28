//
//  CallServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation

class CallServiceImpl: NSObject {
    
    var delegate: CallServiceDelegate?
    
    var status: LocalUserStatus = .free
    
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
        command.callees = [userID]
        command.callID = callID
        command.type = type
        
        callInfo.callID = callID
        callInfo.caller = ServiceManager.shared.userService.localUserInfo
        callInfo.callees = ServiceManager.shared.userService.userList.filter({ $0.userID == userID })
        
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                callResult = .success(())
                ServiceManager.shared.roomService.joinRoom(callID, token)
            case .failure(let error):
                callResult = .failure(error)
                self.status = .free
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func cancelCall(userID: String, callback: RoomCallback?) {
        let command = CancelCallCommand()
        command.calleeID = userID
        command.callID = callInfo.callID
        
        ServiceManager.shared.roomService.leaveRoom()
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                self.status = .free
                self.callInfo = CallInfo()
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func acceptCall(_ token: String, callback: RoomCallback?) {
        let command = AcceptCallCommand()
        command.userID = ServiceManager.shared.userService.localUserInfo?.userID ?? ""
        command.callID = callInfo.callID
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                self.status = .calling
                if let roomID = self.callInfo.callID {
                    ServiceManager.shared.roomService.joinRoom(roomID, token)
                }
                callResult = .success(())
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func declineCall(_ userID: String, type: DeclineType, callback: RoomCallback?) {
        let command = DeclineCallCommand()
        command.userID = userID
        command.callID = callInfo.callID
        command.callerID = callInfo.caller?.userID
        command.type = type
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                self.status = .free
                callResult = .success(())
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
        
        ServiceManager.shared.roomService.leaveRoom()
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                self.status = .free
                callResult = .success(())
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
        let callID = userID + String(Int(Date().timeIntervalSince1970 * 1000))
        print("[*] Generate call ID.... : \(callID)")
        return callID
    }
    
    private func registerListener() {
        
        listener?.registerListener(self, for: Notify_Call_Invited, callback: { result in
            guard let callID = result["call_id"] as? String,
                  let callerID = result["caller_id"] as? String,
                  let callTypeOld = result["call_type"] as? Int,
                  let calleeIDs = result["callee_ids"] as? [String]
            else { return }
            guard let callType = CallType.init(rawValue: callTypeOld) else { return }
            
            if self.status != .free { return }
            self.status = .incoming
            self.callInfo.callID = callID
            
            var caller = UserInfo(userID: callerID, userName: "")
            for user in ServiceManager.shared.userService.userList {
                guard let userID = user.userID else { continue }
                if userID == callerID {
                    caller = user
                }
                if calleeIDs.contains(userID) {
                    self.callInfo.callees.append(user)
                }
            }
            self.callInfo.caller = caller
            self.delegate?.onReceiveCallInvited(caller, type: callType)
        })
        
        listener?.registerListener(self, for: Notify_Call_Canceled, callback: { result in
            guard let callID = result["call_id"] as? String,
                  let callerID = result["caller_id"] as? String
            else {
                return
            }
            if self.callInfo.callID != callID { return }
            if self.status != .incoming { return }
            if self.callInfo.caller?.userID != callerID { return }
            guard let caller = self.callInfo.caller else { return }
            self.status = .free
            self.callInfo = CallInfo()
            self.delegate?.onReceiveCallCanceled(caller)
        })
        
        listener?.registerListener(self, for: Notify_Call_Accept, callback: { result in
            guard let callID = result["call_id"] as? String,
                  let calleeID = result["callee_id"] as? String
            else {
                return
            }
            if self.callInfo.callID != callID { return }
            if self.status != .outgoing { return }
            guard let callee = self.callInfo.callees.filter({ $0.userID == calleeID }).first else {
                return
            }
            self.status = .calling
            self.delegate?.onReceiveCallAccepted(callee)
        })
        
        listener?.registerListener(self, for: Notify_Call_Decline, callback: { result in
            guard let callID = result["call_id"] as? String,
                  let calleeID = result["callee_id"] as? String,
                  let typeOld = result["type"] as? Int,
                  let type = DeclineType.init(rawValue: typeOld)
            else {
                return
            }
            if self.callInfo.callID != callID { return }
            if self.status != .outgoing { return }
            guard let callee = self.callInfo.callees.filter({ $0.userID == calleeID }).first else {
                return
            }
            ServiceManager.shared.roomService.leaveRoom()
            self.status = .free
            self.callInfo = CallInfo()
            self.delegate?.onReceiveCallDeclined(callee, type: type)
        })
        
        listener?.registerListener(self, for: Notify_Call_End, callback: { result in
            guard let callID = result["call_id"] as? String,
                  let userID = result["user_id"] as? String
            else {
                return
            }
            if self.callInfo.callID != callID { return }
            if self.status != .calling { return }
            // cann't receive myself ended call
            if ServiceManager.shared.userService.localUserInfo?.userID == userID { return }
            // the user ended call is not caller or callees
            if self.callInfo.caller?.userID != userID &&
                !self.callInfo.callees.compactMap({ $0.userID }).contains(userID) {
                return
            }
            ServiceManager.shared.roomService.leaveRoom()
            self.status = .free
            self.callInfo = CallInfo()
            self.delegate?.onReceiveCallEnded()
        })
        
        listener?.registerListener(self, for: Notify_Call_Timeout, callback: { result in
            
        })
        
        listener?.registerListener(self, for: Notify_User_Error, callback: { result in
            
        })
        
        listener?.registerListener(self, for: Notify_User_Error, callback: { result in
            guard let code = result["error"] as? Int else { return }
            guard let error = UserError.init(rawValue: code) else { return }
            if error == .kickedOut {
                self.status = .free
                self.callInfo = CallInfo()
                ServiceManager.shared.roomService.leaveRoom()
            }
        })
    }
}
