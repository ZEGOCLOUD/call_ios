//
//  CallMinimizedDisplayManager.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/16.
//

import UIKit
import ZegoExpressEngine

enum MinimizedCallType: Int {
    case audio = 1
    case video = 2
}

enum MinimizedCallStatus: Int {
    case waiting
    case decline
    case calling
    case miss
    case end
}

protocol MinimizedDisplayManagerDelegate: AnyObject {
    func didClickAudioMinimizeView(_ type: MinimizedCallType)
    func didClickVideoMinimizedView()
}

class MinimizedDisplayManager: NSObject, MinimizeCallViewDelegate, VideoMinimizeCallViewDelegate {
    
    weak var delegate: MinimizedDisplayManagerDelegate?
    var currentStatus: MinimizedCallStatus = .waiting
    var viewHiden: Bool = true
    var callType: MinimizedCallType = .audio
    
    func didClickVideoMinimizeCallView() {
        delegate?.didClickVideoMinimizedView()
    }
    
    func didClickMinimizeCallView() {
        delegate?.didClickAudioMinimizeView(callType)
    }
    
    
    lazy var audioMinView: MinimizeCallView = {
        let view = MinimizeCallView.initMinimizeCall("wait...")
        view.delegate = self
        view.isHidden = true
        KeyWindow().addSubview(view)
        return view
    }()
    
    lazy var videoMinView: VideoMinimizeCallView = {
        let view = VideoMinimizeCallView.initVideoMinimizeCall(.calling)
        view.delegate = self
        view.isHidden = true
        KeyWindow().addSubview(view)
        return view
    }()
    
    func showCallMinView(_ callType: MinimizedCallType, status:MinimizedCallStatus, userInfo: UserInfo?) {
        self.callType = callType
        switch callType {
        case .audio:
            audioMinView.isHidden = false
            videoMinView.isHidden = true
            audioMinView.updateCallText(getDisplayText(status))
        case .video:
            showVideoStream(status, userInfo: userInfo)
        }
    }
    
    func showVideoStream(_ status:MinimizedCallStatus, userInfo: UserInfo?) {
        updateCallStatus(status: status, userInfo: userInfo, isVideo: true)
    }
    
    func updateCallStatus(status:MinimizedCallStatus, userInfo: UserInfo?, isVideo: Bool = false) {
        currentStatus = status
        guard let localUserInfo = ServiceManager.shared.userService.localUserInfo else { return }
        if isVideo {
            if let userInfo = userInfo,
               status == .calling {
                if userInfo.camera {
                    audioMinView.isHidden = true
                    videoMinView.isHidden = false
                    videoMinView.streamPreview.isHidden = false
                    ServiceManager.shared.streamService.startPlaying(userInfo.userID, streamView: videoMinView.streamPreview)
                    if localUserInfo.camera {
                        ServiceManager.shared.streamService.startPlaying(localUserInfo.userID, streamView: videoMinView.localVideoPreview)
                    }
                } else {
                    videoMinView.streamPreview.isHidden = true
                    if localUserInfo.camera {
                        audioMinView.isHidden = true
                        audioMinView.updateCallText(getDisplayText(status))
                        videoMinView.isHidden = false
                        ServiceManager.shared.streamService.startPlaying(localUserInfo.userID, streamView: videoMinView.localVideoPreview)
                    } else {
                        audioMinView.isHidden = false
                        audioMinView.updateCallText(getDisplayText(status))
                        videoMinView.isHidden = true
                    }
                }
            } else {
                if localUserInfo.camera {
                    audioMinView.isHidden = true
                    videoMinView.isHidden = false
                    let streamID = localUserInfo.userID
                    ServiceManager.shared.streamService.startPlaying(streamID, streamView: videoMinView.localVideoPreview)
                } else {
                    audioMinView.isHidden = false
                    audioMinView.updateCallText(getDisplayText(status))
                    videoMinView.isHidden = true
                }
            }
        } else {
            audioMinView.isHidden = false
            audioMinView.updateCallText(getDisplayText(status))
            videoMinView.isHidden = true
        }
        if viewHiden {
            audioMinView.isHidden = true
            videoMinView.isHidden = true
        }
    }
    
    func updateCallTimeText(_ text: String?) {
        if currentStatus == .calling {
            audioMinView.updateCallText(text)
        }
    }
    
    func getDisplayText(_ status: MinimizedCallStatus) -> String? {
        switch status {
        case .waiting:
            return "wait..."
        case .decline:
            return "Declined"
        case .calling:
            return nil
        case .miss:
            return "Missed"
        case .end:
            return "Ended"
        }
    }
    
    func dismissCallMinView() {
        viewHiden = true
        audioMinView.isHidden = true
        videoMinView.isHidden = true
    }
    
}
