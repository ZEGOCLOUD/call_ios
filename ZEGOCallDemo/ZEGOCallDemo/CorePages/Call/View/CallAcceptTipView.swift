//
//  CallAcceptTipView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

class CallAcceptTipView: CallBaseView {
    
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    
    @IBAction func declineButtonClick(_ sender: UIButton) {
        delegate?.callDecline(self)
    }
    
    @IBAction func acceptButtonClick(_ sender: UIButton) {
        delegate?.callAccept(self)
    }
    
}
