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
        delegate?.callOpenMic(true)
    }
    
    @IBAction func handUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp()
    }
    
    @IBAction func voiceButtonClick(_ sender: UIButton) {
        delegate?.callOpenVoice(true)
    }

}
