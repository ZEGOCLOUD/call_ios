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
        guard let userInfo = ServiceManager.shared.userService.localUserInfo else { return }
        userInfo.camera = !userInfo.camera
        delegate?.callOpenVideo(self, isOpen: userInfo.camera)
        changeDisplayStatus()
    }
    
    @IBAction func micButtonClick(_ sender: UIButton) {
        guard let userInfo = ServiceManager.shared.userService.localUserInfo else { return }
        userInfo.mic = !userInfo.mic
        delegate?.callOpenMic(self, isOpen: userInfo.mic)
        changeDisplayStatus()
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp(self)
    }
    
    @IBAction func flipButtonClick(_ sender: UIButton) {
        delegate?.callFlipCamera(self)
    }
    
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        if ServiceManager.shared.deviceService.routeType != .receiver &&
            ServiceManager.shared.deviceService.routeType != .speaker {
            return
        }
        let enable = ServiceManager.shared.deviceService.routeType == .receiver
        delegate?.callOpenVoice(self, isOpen: enable)
        changeDisplayStatus()
    }
    
    func changeDisplayStatus() {
        guard let userInfo = ServiceManager.shared.userService.localUserInfo else { return }
        
        let cameraImage = userInfo.camera ? "call_camera_open_icon" : "call_camera_close_icon"
        videoButton.setImage(UIImage(named: cameraImage), for: .normal)
        
        let micImage = userInfo.mic ? "call_audio_mic_open" : "call_audio_mic_close"
        micButton.setImage(UIImage(named: micImage), for: .normal)
        
        let routeType = ServiceManager.shared.deviceService.routeType
        var voiceImage =  "call_audio_voice_close"
        switch routeType {
        case .speaker:
            voiceImage = "call_audio_voice_open"
        case .headphone:
            voiceImage = "call_audio_voice_close"
        case .bluetooth:
            voiceImage = "call_voice_bluetooth_icon"
        case .receiver:
            voiceImage = "call_audio_voice_close"
        case .externalUSB:
            voiceImage = "call_audio_voice_close"
        case .airPlay:
            voiceImage = "call_audio_voice_close"
        @unknown default:
            voiceImage = "call_audio_voice_close"
        }
        voiceButton.setImage(UIImage(named: voiceImage), for: .normal)
    }
    
}
