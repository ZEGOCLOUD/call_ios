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
    
    
    @IBAction func declineButtonClick(_ sender: UIButton) {
        delegate?.callDecline()
    }
    
    
    @IBAction func acceptButtonClick(_ sender: UIButton) {
        delegate?.callAccept()
    }
    
}
