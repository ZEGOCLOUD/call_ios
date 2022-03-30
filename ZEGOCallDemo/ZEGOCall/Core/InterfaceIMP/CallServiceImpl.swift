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
    
    private var callTask: Task?
    private let heartbeatTimer = ZegoTimer(10 * 1000)
    
    override init() {
        super.init()
        
        registerListener()
    }
}

extension CallServiceImpl: CallService {
    func callUser(_ userID: String, token: String, type: CallType, callback: ZegoCallback?) {
        
        self.status = .outgoing
        
        let callerUserID = ServiceManager.shared.userService.localUserInfo?.userID ?? ""
        let callID = generateCallID(callerUserID)
        
        let command = CallCommand()
        command.userID = callerUserID
        command.callees = [userID]
        command.callID = callID
        command.callerName = ServiceManager.shared.userService.localUserInfo?.userName
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
                self.addCallTimer()
            case .failure(let error):
                callResult = .failure(error)
                self.status = .free
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func cancelCall(userID: String, callback: ZegoCallback?) {
        let command = CancelCallCommand()
        command.calleeID = userID
        command.callID = callInfo.callID
        
        ServiceManager.shared.roomService.leaveRoom()
        
        self.status = .free
        self.callInfo = CallInfo()
        self.cancelCallTimer()
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                break
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func acceptCall(_ token: String, callback: ZegoCallback?) {
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
                self.cancelCallTimer()
                self.startHeartbeatTimer()
                
                callResult = .success(())
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func declineCall(_ userID: String, type: DeclineType, callback: ZegoCallback?) {
        let command = DeclineCallCommand()
        command.userID = userID
        command.callID = callInfo.callID
        command.callerID = callInfo.caller?.userID
        command.type = type
        
        self.status = .free
        self.cancelCallTimer()
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
                callResult = .success(())
            case .failure(let error):
                callResult = .failure(error)
            }
            guard let callback = callback else { return }
            callback(callResult)
        }
    }
    
    func endCall(_ callback: ZegoCallback?) {
        let command = EndCallCommand()
        command.userID = ServiceManager.shared.userService.localUserInfo?.userID ?? ""
        command.callID = callInfo.callID
        
        ServiceManager.shared.roomService.leaveRoom()
        self.status = .free
        self.stopHeartbeatTimer()
        
        command.excute { result in
            var callResult: ZegoResult = .success(())
            switch result {
            case .success(_):
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
                
        _ = listener?.addListener(Notify_Call_Invited, listener: { result in
            guard let callID = result["call_id"] as? String,
                  let callerID = result["caller_id"] as? String,
                  let callerName = result["caller_name"] as? String,
                  let callTypeOld = result["call_type"] as? Int,
                  let calleeIDs = result["callee_ids"] as? [String]
            else { return }
            guard let callType = CallType.init(rawValue: callTypeOld) else { return }
            
            if self.status != .free { return }
            self.status = .incoming
            self.callInfo.callID = callID
            self.addCallTimer()
            
            var caller = UserInfo(userID: callerID, userName: callerName)
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
        
        _ = listener?.addListener(Notify_Call_Canceled, listener: { result in
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
            self.cancelCallTimer()
            
            self.delegate?.onReceiveCallCanceled(caller)
        })
        
        _ = listener?.addListener(Notify_Call_Accept, listener: { result in
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
            
            self.cancelCallTimer()
            self.startHeartbeatTimer()
            
            self.status = .calling
            self.delegate?.onReceiveCallAccepted(callee)
        })

        _ = listener?.addListener(Notify_Call_Decline, listener: { result in
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
            
            self.cancelCallTimer()
            ServiceManager.shared.roomService.leaveRoom()
            self.status = .free
            self.callInfo = CallInfo()
            self.delegate?.onReceiveCallDeclined(callee, type: type)
        })
        
        _ = listener?.addListener(Notify_Call_End, listener: { result in
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
            self.stopHeartbeatTimer()
            ServiceManager.shared.roomService.leaveRoom()
            self.status = .free
            self.callInfo = CallInfo()
            self.delegate?.onReceiveCallEnded()
        })
        
        _ = listener?.addListener(Notify_Call_Timeout, listener: { result in
            self.stopHeartbeatTimer()
        })
        
        _ = listener?.addListener(Notify_User_Error, listener: { result in
            guard let code = result["error"] as? Int else { return }
            guard let error = UserError.init(rawValue: code) else { return }
            if error == .kickedOut {
                self.status = .free
                self.callInfo = CallInfo()
                ServiceManager.shared.roomService.leaveRoom()
                self.cancelCallTimer()
                self.stopHeartbeatTimer()
            }
        })
    }
}

extension CallServiceImpl {
    func addCallTimer() {
        callTask = delay(by: 60) { [weak self] in
            guard let user = ServiceManager.shared.userService.localUserInfo else { return }
            self?.delegate?.onReceiveCallTimeout(.connecting, info: user)
        }
    }
    
    func cancelCallTimer() {
        delayCancel(callTask)
        callTask = nil
    }
    
    func startHeartbeatTimer() {
        heartbeatTimer.setEventHandler { [weak self] in
            let command = HeartbeatCommand()
            command.userID = ServiceManager.shared.userService.localUserInfo?.userID
            command.callID = self?.callInfo.callID
            command.excute(callback: nil)
        }
        heartbeatTimer.start()
    }
    
    func stopHeartbeatTimer() {
        heartbeatTimer.stop()
    }
}
