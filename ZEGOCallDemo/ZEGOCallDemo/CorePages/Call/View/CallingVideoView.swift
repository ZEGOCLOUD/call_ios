//
//  CallingVideoView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

class CallingVideoView: CallBaseView {
    
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var voiceButton: UIButton!
    
    
    @IBAction func videoButtonClick(_ sender: UIButton) {
        guard let userInfo = RoomManager.shared.userService.localUserInfo else { return }
        delegate?.callOpenVideo(self, isOpen: !userInfo.camera)
        if !userInfo.camera {
            videoButton.setImage(UIImage(named: "call_camera_open_icon"), for: .normal)
        } else {
            videoButton.setImage(UIImage(named: "call_camera_close_icon"), for: .normal)
        }
        RoomManager.shared.userService.localUserInfo?.camera = !userInfo.camera
    }
    
    @IBAction func micButtonClick(_ sender: UIButton) {
        guard let userInfo = RoomManager.shared.userService.localUserInfo else { return }
        delegate?.callOpenMic(self, isOpen: !userInfo.mic)
        if !userInfo.mic {
            micButton.setImage(UIImage(named: "call_mic_selected_open"), for: .normal)
        } else {
            micButton.setImage(UIImage(named: "call_mic_selected_close"), for: .normal)
        }
        RoomManager.shared.userService.localUserInfo?.mic = !userInfo.mic
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp(self)
    }
    
    @IBAction func flipButtonClick(_ sender: UIButton) {
        delegate?.callFlipCamera(self)
    }
    
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        guard let userInfo = RoomManager.shared.userService.localUserInfo else { return }
        if !userInfo.voice {
            voiceButton.setImage(UIImage(named: "call_voice_close_selected_icon"), for: .normal)
        } else {
            voiceButton.setImage(UIImage(named: "call_voice_open_selected_icon"), for: .normal)
        }
        delegate?.callOpenVoice(self, isOpen: !userInfo.voice)
        RoomManager.shared.userService.localUserInfo?.voice = !userInfo.voice
    }
    
    
}
