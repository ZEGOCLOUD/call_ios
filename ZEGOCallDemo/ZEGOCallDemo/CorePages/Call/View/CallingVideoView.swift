//
//  CallingVideoView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

class CallingVideoView: CallBaseView {
    
    

    
    @IBAction func videoButtonClick(_ sender: UIButton) {
        delegate?.callOpenVideo(true)
    }
    
    @IBAction func micButtonClick(_ sender: UIButton) {
        delegate?.callOpenMic(true)
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp()
    }
    
    @IBAction func flipButtonClick(_ sender: UIButton) {
        delegate?.callFlipCamera()
    }
    
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        delegate?.callOpenVoice(true)
    }
    
    
}
