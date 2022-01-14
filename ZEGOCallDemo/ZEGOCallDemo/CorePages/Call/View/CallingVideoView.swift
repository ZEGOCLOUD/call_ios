//
//  CallingVideoView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

class CallingVideoView: CallBaseView {
    
    

    
    @IBAction func videoButtonClick(_ sender: UIButton) {
        delegate?.callOpenVideo(self, isOpen: true)
    }
    
    @IBAction func micButtonClick(_ sender: UIButton) {
        delegate?.callOpenMic(self, isOpen: true)
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp(self)
    }
    
    @IBAction func flipButtonClick(_ sender: UIButton) {
        delegate?.callFlipCamera(self)
    }
    
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        delegate?.callOpenVoice(self, isOpen: true)
    }
    
    
}
