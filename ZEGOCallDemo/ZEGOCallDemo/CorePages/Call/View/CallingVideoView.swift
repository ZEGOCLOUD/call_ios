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
        guard let userInfo = RoomManager.shared.userService.localUserRoomInfo else { return }
        userInfo.camera = !userInfo.camera
        delegate?.callOpenVideo(self, isOpen: userInfo.camera)
        if userInfo.camera {
            videoButton.setImage(UIImage(named: "call_camera_open_icon"), for: .normal)
        } else {
            videoButton.setImage(UIImage(named: "call_camera_close_icon"), for: .normal)
        }
    }
    
    @IBAction func micButtonClick(_ sender: UIButton) {
        guard let userInfo = RoomManager.shared.userService.localUserRoomInfo else { return }
        userInfo.mic = !userInfo.mic
        delegate?.callOpenMic(self, isOpen: userInfo.mic)
        if userInfo.mic {
            micButton.setImage(UIImage(named: "call_mic_selected_open"), for: .normal)
        } else {
            micButton.setImage(UIImage(named: "call_mic_selected_close"), for: .normal)
        }
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp(self)
    }
    
    @IBAction func flipButtonClick(_ sender: UIButton) {
        delegate?.callFlipCamera(self)
    }
    
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        guard let userInfo = RoomManager.shared.userService.localUserRoomInfo else { return }
        let voice = userInfo.voice ?? false
        userInfo.voice = !voice
        if userInfo.voice! {
            voiceButton.setImage(UIImage(named: "call_voice_close_icon"), for: .normal)
        } else {
            voiceButton.setImage(UIImage(named: "call_voice_open_icon"), for: .normal)
        }
        delegate?.callOpenVoice(self, isOpen: userInfo.voice!)
    }
    
    
}
