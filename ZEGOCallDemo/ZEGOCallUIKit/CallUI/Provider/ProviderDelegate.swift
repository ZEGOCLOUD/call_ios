//
//  ProviderDelegate.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import CallKit
import AVFoundation
import UIKit

class ProviderDelegate: NSObject,CXProviderDelegate {
    private let provider:CXProvider
    
    private let callController = CXCallController()
    /// The app's provider configuration, representing its CallKit capabilities
    static var providerConfiguration: CXProviderConfiguration {
        let localizedName = "ZEGOCallDemo"
        let providerConfiguration = CXProviderConfiguration(localizedName: localizedName)
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        
        if let iconMaskImage = UIImage(named: "IconMask") {
            providerConfiguration.iconTemplateImageData =  iconMaskImage.pngData()
        }
        
        providerConfiguration.ringtoneSound = "Ringtone.caf"
        
        return providerConfiguration
    }
    
    override init() {
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    //MARK: - Call
    
    func call(_ uuid: UUID, handle:String) {
        let startCallAction = CXStartCallAction(call: uuid,handle: CXHandle(type: .generic, value: handle))
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        callController.request(transaction) { (err) in
            print(err)
        }
    }
    //MARK: - Ending Call
    func endCall(uuid : UUID, completion: @escaping (UUID) -> Void) {
        let trans = CXTransaction()
        let action = CXEndCallAction(call: uuid)
        trans.addAction(action)
        
        callController.request(trans, completion: { (err) in
            print(err)
            completion(uuid)
        })
        
    }

    
    // MARK: Incoming Calls
    
    /// Use CXProvider to report the incoming call to the system
    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)? = nil) {
        // Construct a CXCallUpdate describing the incoming call, including the caller.
        do{
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        } catch {
            print(error)
        }
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        update.hasVideo = hasVideo
        update.localizedCallerName = CallManager.shared.currentCallUserInfo?.userName
        
        // Report the incoming call to the system
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            /*
             Only add incoming call to the app's list of calls if the call was allowed (i.e. there was no error)
             since calls may be "denied" for various legitimate reasons. See CXErrorCodeIncomingCallError.
             */
            if error == nil {
                print("calling")
                
            }
        }
    }
    
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        let update = CXCallUpdate()
        update.remoteHandle = action.handle
        provider.reportOutgoingCall(with: action.uuid, startedConnectingAt: Date())
//        NotificationCenter.default.post(name: Notification.Name(CALL_NOTI_START), object: self, userInfo: ["uuid":action.uuid])
        action.fulfill(withDateStarted: Date())
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NotificationCenter.default.post(name: Notification.Name(CALL_NOTI_START), object: self, userInfo: ["uuid":action.uuid])
        action.fulfill(withDateConnected: Date())
    }
    
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NotificationCenter.default.post(name: Notification.Name(CALL_NOTI_END), object: self, userInfo: ["uuid":action.uuid.uuidString])
        action.fulfill(withDateEnded: Date())
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        action.fulfill()
        if UIApplication.shared.applicationState != .active {
            NotificationCenter.default.post(name: Notification.Name(CALL_NOTI_MUTE), object: self, userInfo: ["isMute": action.isMuted,"uuid":action.uuid.uuidString])
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        
    }
    
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        action.fulfill()
        print("Timed out \(#function)")
        // React to the action timeout if necessary, such as showing an error UI.
    }
    
    
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Received \(#function)")
        
    }
    
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Received \(#function)")
        /*
         Restart any non-call related audio now that the app's audio session has been
         de-activated after having its priority restored to normal.
         */
    }

}
