//
//  StreamServiceIMP.swift
//  ZEGOCallDemo
//
//  Created by Kael Ding on 2022/3/19.
//

import Foundation
import ZegoExpressEngine

class StreamServiceImpl: NSObject {
    
}

extension StreamServiceImpl: StreamService {
    func startPlaying(_ userID: String?, streamView: UIView?) {
        
        assert(ServiceManager.shared.isSDKInit, "The SDK must be initialised first.")
        assert(ServiceManager.shared.userService.localUserInfo != nil, "Must be logged in first.")
        assert(userID != nil, "The user ID can not be nil.")
        
        guard let roomID = ServiceManager.shared.roomService.roomInfo?.roomID else {
            assert(false, "The room ID can not be nil")
            return
        }
        let streamID = String.getStreamID(userID, roomID: roomID)
        if streamView != nil {
            guard let streamView = streamView else { return }
            let canvas = ZegoCanvas(view: streamView)
            canvas.viewMode = .aspectFill
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
        } else {
            ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: nil)
        }
    }
    
    func startPreview(_ streamView: UIView?) {
        
        assert(ServiceManager.shared.isSDKInit, "The SDK must be initialised first.")
        assert(ServiceManager.shared.userService.localUserInfo != nil, "Must be logged in first.")
        
        guard let streamView = streamView else {
            assert(false, "The stream view can not be nil.")
            return
        }
        let canvas = ZegoCanvas(view: streamView)
        canvas.viewMode = .aspectFill
        ZegoExpressEngine.shared().startPreview(canvas)
    }
    
    func stopPlaying(_ userID: String?) {
        guard let roomID = ServiceManager.shared.roomService.roomInfo?.roomID else {
            assert(false, "The room ID can not be nil")
            return
        }
        let streamID = String.getStreamID(userID, roomID: roomID)
        ZegoExpressEngine.shared().stopPlayingStream(streamID)
    }
}
