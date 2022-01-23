//
//  RoomService+Private.swift
//  ZEGOLiveDemo
//
//  Created by Kael Ding on 2021/12/27.
//

import Foundation
import ZIM
import ZegoExpressEngine

extension RoomService {
    
    func roomAttributesUpdated(_ roomAttributes: [String: String]) {
        // update room info
        delegate?.receiveRoomInfoUpdate(roomAttributes)
    }
    
}
