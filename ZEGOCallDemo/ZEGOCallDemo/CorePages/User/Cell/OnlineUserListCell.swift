//
//  OnlineUserListCell.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit

enum CallActionType: Int {
    case phone
    case video
}

protocol OnlineUserListCellDelegate: AnyObject {
    func startCall(_ type: CallActionType)
}

class OnlineUserListCell: UITableViewCell {
    
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    
    weak var delegate: OnlineUserListCellDelegate?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateCell(_ model: UserInfo) {
        userIDLabel.text = model.userID
        userNameLabel.text = model.userName
    }

    @IBAction func startVideoClick(_ sender: UIButton) {
        delegate?.startCall(.video)
    }
    
    @IBAction func startPhoneClick(_ sender: UIButton) {
        delegate?.startCall(.phone)
    }

}
