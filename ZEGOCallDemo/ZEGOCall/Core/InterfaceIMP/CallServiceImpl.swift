//
//  CallServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/15.
//

import Foundation
import ZegoExpressEngine

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
        
        // ServiceManager didn't finish init at this time.
        DispatchQueue.main.async {
            ServiceManager.shared.addExpressEventHandler(self)
        }
    }
}

extension CallServiceImpl: CallService {
    func callUser(_ user: UserInfo, token: String, type: CallType, callback: ZegoCallback?) {
        
        self.status = .outgoing
        
        let callerUserID = ServiceManager.shared.userService.localUserInfo?.userID ?? ""
        let callID = generateCallID(callerUserID)
        
        let command = CallCommand()
        command.caller = ServiceManager.shared.userService.localUserInfo
        command.callees = [user]
        command.callID = callID
        command.type = type
        
        callInfo.callID = callID
        callInfo.caller = ServiceManager.shared.userService.localUserInfo
        callInfo.callees = [user]
        
        
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
        command.userID = ServiceManager.shared.userService.localUserInfo?.userID
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
    
    private func getUser(_ userID: String) -> UserInfo? {
        if self.callInfo.caller?.userID == userID {
            return self.callInfo.caller
        }
        for user in self.callInfo.callees {
            if user.userID == userID {
                return user
            }
        }
        return nil
    }
    
    private func registerListener() {
                
        _ = listener?.addListener(Notify_Call_Invited, listener: { result in
            guard let callID = result["call_id"] as? String,
                  let caller = result["caller"] as? UserInfo,
                  let callees = result["callees"] as? [UserInfo],
                  let callTypeOld = result["call_type"] as? Int
            else { return }
            guard let callType = CallType.init(rawValue: callTypeOld) else { return }
            
            defer {
                self.delegate?.onReceiveCallInvited(caller, type: callType)
            }
            
            if self.status != .free { return }
            self.status = .incoming
            self.callInfo.callID = callID
            self.addCallTimer()
            
            self.callInfo.caller = caller
            self.callInfo.callees = callees
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
            guard let callID = result["call_id"] as? String,
                  let userID = result["user_id"] as? String
            else {
                return
            }
            if self.status != .calling { return }
            if self.callInfo.callID != callID { return }
            guard let user = self.getUser(userID) else { return }
            self.status = .free
            self.stopHeartbeatTimer()
            ServiceManager.shared.roomService.leaveRoom()
            self.delegate?.onReceiveCallTimeout(.calling, info: user)
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

extension CallServiceImpl: ZegoEventHandler {
    func onRoomStateUpdate(_ state: ZegoRoomState, errorCode: Int32, extendedData: [AnyHashable : Any]?, roomID: String) {
        print("[*] onRoomStateUpdate: \(state.rawValue), errorCode: \(errorCode), roomID: \(roomID)")
        // if myself disconnected, just callback the `timeout`.
        if state == .disconnected && self.status == .calling {
            guard let user = ServiceManager.shared.userService.localUserInfo else { return }
            ServiceManager.shared.roomService.leaveRoom()
            delegate?.onReceiveCallTimeout(.calling, info: user)
            stopHeartbeatTimer()
        }
    }
}
