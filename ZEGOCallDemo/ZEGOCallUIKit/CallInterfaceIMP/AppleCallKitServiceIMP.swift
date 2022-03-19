//
//  AppleCallKitServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/18.
//

import UIKit

class AppleCallKitServiceIMP: NSObject, AppleCallKitService {
    
    var providerDelegate: ProviderDelegate?
    
    func reportInComingCall(uuid: UUID, handle: String, hasVideo: Bool, completion: ((NSError?) -> Void)?) {
        guard let providerDelegate = providerDelegate else { return }
        providerDelegate.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
}
