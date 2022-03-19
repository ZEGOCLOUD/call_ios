//
//  CallMinimizedDisplayManager.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/16.
//

import UIKit

enum MinimizedCallType: Int {
    case audio
    case video
}

enum MinimizedCallStatus: Int {
    case waiting
    case decline
    case calling
    case miss
    case end
}

protocol MinimizedDisplayManagerDelegate: AnyObject {
    func didClickAudioMinimizeView()
    func didClickVideoMinimizedView()
    
}

class MinimizedDisplayManager: NSObject, MinimizeCallViewDelegate, VideoMinimizeCallViewDelegate {
    
    weak var delegate: MinimizedDisplayManagerDelegate?
    
    func didClickVideoMinimizeCallView() {
        delegate?.didClickVideoMinimizedView()
    }
    
    func didClickMinimizeCallView() {
        delegate?.didClickAudioMinimizeView()
    }
    
    
    lazy var audioMinView: MinimizeCallView = {
        let view = MinimizeCallView.initMinimizeCall(.waiting)
        view.delegate = self
        view.isHidden = true
        return view
    }()
    
    lazy var videoMinView: VideoMinimizeCallView = {
        let view = VideoMinimizeCallView.initVideoMinimizeCall(.calling)
        view.delegate = self
        view.isHidden = true
        return view
    }()
    
    func showCallMinView(_ callType: MinimizedCallType, status:MinimizedCallStatus, userInfo: UserInfo?) {
        switch callType {
        case .audio:
            audioMinView.isHidden = false
            videoMinView.isHidden = true
            audioMinView.updateCallStatus(status)
        case .video:
            showVideoStream(status, userInfo: userInfo)
        }
    }
    
    func showVideoStream(_ status:MinimizedCallStatus, userInfo: UserInfo?) {
        updateCallStatus(status: status, userInfo: userInfo)
    }
    
    func updateCallStatus(status:MinimizedCallStatus, userInfo: UserInfo?) {
        guard let localUserInfo = ServiceManager.shared.userService.localUserInfo else { return }
        if let userInfo = userInfo {
            if userInfo.camera || localUserInfo.camera {
                audioMinView.isHidden = false
                videoMinView.isHidden = true
                let streamID = userInfo.camera ? userInfo.userID : localUserInfo.userID
                ServiceManager.shared.streamService.startPlaying(streamID, streamView: videoMinView.videoPreview)
            } else {
                audioMinView.isHidden = false
                audioMinView.updateCallStatus(status)
                videoMinView.isHidden = true
            }
        } else {
            if localUserInfo.camera {
                audioMinView.isHidden = true
                videoMinView.isHidden = false
                let streamID = localUserInfo.userID
                ServiceManager.shared.streamService.startPlaying(streamID, streamView: videoMinView.videoPreview)
            } else {
                audioMinView.isHidden = false
                audioMinView.updateCallStatus(status)
                videoMinView.isHidden = true
            }
        }
    }
    
    func dismissCallMinView() {
        audioMinView.isHidden = true
        videoMinView.isHidden = true
    }
    
}
