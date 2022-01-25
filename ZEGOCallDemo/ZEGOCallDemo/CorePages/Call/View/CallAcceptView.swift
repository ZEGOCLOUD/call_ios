//
//  CallAcceptView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

class CallAcceptView: CallBaseView {
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptLabel: UILabel!
    @IBOutlet weak var declineLabel: UILabel!
    
    func setCallAcceptViewType(_ isVideo: Bool = false) {
        if isVideo {
            acceptButton.setImage(UIImage(named: "call_video_icon"), for: .normal)
        } else {
            acceptButton.setImage(UIImage(named: "call_accept_icon"), for: .normal)
        }
    }
    
    
    @IBAction func declineButtonClick(_ sender: UIButton) {
        delegate?.callDecline(self)
    }
    
    @IBAction func acceptButtonClick(_ sender: UIButton) {
        delegate?.callAccept(self)
    }
    
}
