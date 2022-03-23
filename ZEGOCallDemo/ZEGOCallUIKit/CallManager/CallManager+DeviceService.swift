//
//  CallManager+DeviceService.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/23.
//

import Foundation
import ZegoExpressEngine

extension CallManager: DeviceServiceDelegate {
    func onAudioRouteChange(_ audioRoute: ZegoAudioRoute) {
        currentCallVC?.changeBottomButtonDisplayStatus()
    }
}
