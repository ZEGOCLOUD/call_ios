//
//  AppleCallKitService.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/18.
//

import Foundation

protocol AppleCallKitService {
    
    var providerDelegate: ProviderDelegate? { get set }
    
    func reportInComingCall(uuid: UUID, handle: String, hasVideo: Bool, completion: ((NSError?) -> Void)?)
    
}
