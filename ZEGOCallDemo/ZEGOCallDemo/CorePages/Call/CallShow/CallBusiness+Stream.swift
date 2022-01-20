//
//  CallBusiness+Stream.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/20.
//

import Foundation
import ZegoExpressEngine

extension CallBusiness {
    
    // get local user ID
    var localUserID: String {
        RoomManager.shared.userService.localUserInfo?.userID ?? ""
    }
    
    func startPlaying(_ userID: String?, streamView: UIView?, type: CallType) {
        if type == .video {
            guard let streamView = streamView else { return }
            let streamID = String.getStreamID(userID, roomID: getRoomID(), isVideo: true)
            let canvas = ZegoCanvas(view: streamView)
            canvas.viewMode = .aspectFill
            if isUserMyself(userID) {
                ZegoExpressEngine.shared().startPreview(canvas)
            } else {
                ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
            }
        } else {
            let streamID = String.getStreamID(userID, roomID: getRoomID())
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
