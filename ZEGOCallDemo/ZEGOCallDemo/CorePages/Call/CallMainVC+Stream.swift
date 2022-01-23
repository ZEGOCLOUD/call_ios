//
//  CallMainVC+Stream.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/19.
//

import Foundation
import ZegoExpressEngine

extension CallMainVC {
    
    // get local user ID
    var localUserID: String {
        RoomManager.shared.userService.localUserInfo?.userID ?? ""
    }
    
    func startPlaying(_ userID: String?, streamView: UIView?, type: CallType) {
        let streamID = String.getStreamID(userID, roomID: getRoomID())
        if type == .video {
            guard let streamView = streamView else { return }
            let canvas = ZegoCanvas(view: streamView)
            canvas.viewMode = .aspectFill
            if isUserMyself(userID) {
                ZegoExpressEngine.shared().startPreview(canvas)
            } else {
                ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
            }
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
        }
    }
    
    func isUserMyself(_ userID: String?) -> Bool {
        return localUserID == userID
    }
    
    func getRoomID() -> String {
        return RoomManager.shared.userService.roomService.roomInfo.roomID ?? ""
    }
}


