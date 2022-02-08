//
//  UserService+Express.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/1/28.
//

import Foundation
import ZegoExpressEngine

extension UserService {
    
    func enableCamera(_ enable: Bool) {
        ZegoExpressEngine.shared().enableCamera(enable)
    }
    
    func muteMicrophone(_ mute: Bool) {
        ZegoExpressEngine.shared().muteMicrophone(mute)
    }
    
    func useFrontCamera(_ enable: Bool) {
        ZegoExpressEngine.shared().useFrontCamera(enable)
    }
    
    func enableSpeaker(_ enable: Bool) {
        ZegoExpressEngine.shared().setAudioRouteToSpeaker(enable)
    }
    
    func startPlaying(_ userID: String?, streamView: UIView?) {
        guard let roomID = RoomManager.shared.userService.roomService.roomInfo.roomID else { return }
        let streamID = String.getStreamID(userID, roomID: roomID)
        if streamView != nil {
            guard let streamView = streamView else { return }
            let canvas = ZegoCanvas(view: streamView)
            canvas.viewMode = .aspectFill
            if RoomManager.shared.userService.localUserInfo?.userID == userID {
                ZegoExpressEngine.shared().startPreview(canvas)
            } else {
                ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
            }
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
        }
    }
}
