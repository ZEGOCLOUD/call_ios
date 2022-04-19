//
//  CallManager+RoomService.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/4/14.
//

import Foundation

extension CallManager: RoomServiceDelegate {
    func onRoomTokenWillExpire(_ remainTimeInSecond: Int32, roomID: String) {
        tokenProvider?.getRTCToken({ token in
            guard let token = token else { return }
            ServiceManager.shared.roomService.renewToken(token, roomID: roomID)
        })
    }
}
