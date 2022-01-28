//
//  CallingPhoneView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

class CallingPhoneView: CallBaseView {
    
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var handUpButton: UIButton!
    @IBOutlet weak var voiceButton: UIButton!
    
    
    @IBAction func micButtonClick(_ sender: UIButton) {
        guard let userInfo = RoomManager.shared.userService.localUserRoomInfo else { return }
        userInfo.mic = !userInfo.mic
        delegate?.callOpenMic(self, isOpen: userInfo.mic)
        if userInfo.mic {
            micButton.setImage(UIImage(named: "call_audio_mic_open"), for: .normal)
        } else {
            micButton.setImage(UIImage(named: "call_audio_mic_close"), for: .normal)
        }
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp(self)
    }
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        guard let userInfo = RoomManager.shared.userService.localUserRoomInfo else { return }
        let voice = userInfo.voice ?? false
        userInfo.voice = !voice
        if voice {
            voiceButton.setImage(UIImage(named: "call_audio_voice_close"), for: .normal)
        } else {
            voiceButton.setImage(UIImage(named: "call_audio_voice_open"), for: .normal)
        }
        delegate?.callOpenVoice(self, isOpen: !voice)
    }

}
