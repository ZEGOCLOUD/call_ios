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
        guard let userInfo = ServiceManager.shared.userService.localUserInfo else { return }
        userInfo.mic = !userInfo.mic
        delegate?.callOpenMic(self, isOpen: userInfo.mic)
        changeDisplayStatus()
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp(self)
    }
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        guard let userInfo = ServiceManager.shared.userService.localUserInfo else { return }
        let voice = userInfo.voice ?? false
        userInfo.voice = !voice
        changeDisplayStatus()
        delegate?.callOpenVoice(self, isOpen: !voice)
    }
    
    func changeDisplayStatus() {
        guard let userInfo = ServiceManager.shared.userService.localUserInfo else { return }
        let micImage = userInfo.mic ? "call_audio_mic_open" : "call_audio_mic_close"
        micButton.setImage(UIImage(named: micImage), for: .normal)
        
        let  voiceImage = (userInfo.voice ?? false) ? "call_audio_voice_open" : "call_audio_voice_close"
        voiceButton.setImage(UIImage(named: voiceImage), for: .normal)
    }
    

}
