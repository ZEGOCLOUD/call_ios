//
//  CallMinimizedDisplayManager.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/16.
//

import UIKit
import ZegoExpressEngine

enum MinimizedCallType: Int {
    case audio = 1 /// audio
    case video = 2 /// video
}

enum MinimizedCallStatus: Int {
    case waiting /// waiting state
    case decline /// decline state
    case calling /// calling state
    case miss /// miss state
    case end /// end state
}

protocol MinimizedDisplayManagerDelegate: AnyObject {
    
    /// click audio minimize view callback
    func didClickAudioMinimizeView(_ type: MinimizedCallType)
    /// click video minimize view callback
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
    
    
    /// display call minimize view
    /// - Parameters:
    ///   - callType: call type
    ///   - status: call state
    ///   - userInfo: user info
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
    
    
    /// update call state
    /// - Parameters:
    ///   - status: call state
    ///   - userInfo: user info
    ///   - isVideo: display type video or audio: default false
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
                        ServiceManager.shared.streamService.startPreview(videoMinView.localVideoPreview)
                    }
                } else {
                    videoMinView.streamPreview.isHidden = true
                    if localUserInfo.camera {
                        audioMinView.isHidden = true
                        audioMinView.updateCallText(getDisplayText(status))
                        videoMinView.isHidden = false
                        ServiceManager.shared.streamService.startPreview(videoMinView.localVideoPreview)
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
                    if status == .waiting {
                        ServiceManager.shared.streamService.startPreview(videoMinView.localVideoPreview)
                    }
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
            return ZGUIKitLocalizedString("call_page_status_waiting")
        case .decline:
            return ZGUIKitLocalizedString("call_page_status_declined")
        case .calling:
            return nil
        case .miss:
            return ZGUIKitLocalizedString("call_page_status_missed")
        case .end:
            return ZGUIKitLocalizedString("call_page_status_ended")
        }
    }
    
    /// Hide minimize view
    func dismissCallMinView() {
        viewHiden = true
        audioMinView.isHidden = true
        videoMinView.isHidden = true
    }
    
}
