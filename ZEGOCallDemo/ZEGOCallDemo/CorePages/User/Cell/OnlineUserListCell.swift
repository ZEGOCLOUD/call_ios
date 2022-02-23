//
//  OnlineUserListCell.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit

protocol OnlineUserListCellDelegate: AnyObject {
    func startCall(_ type: CallType, userInfo: UserInfo)
}

class OnlineUserListCell: UITableViewCell {
    
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    
    
    weak var delegate: OnlineUserListCellDelegate?
    var cellModel: UserInfo?
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateCell(_ model: UserInfo) {
        cellModel = model
        userIDLabel.text = "ID:\(model.userID ?? "")"
        userNameLabel.text = model.userName
        headImage.image = UIImage(named: String.getHeadImageName(userName: model.userName))
        if model.userID == RoomManager.shared.userService.localUserInfo?.userID {
            phoneButton.isHidden = true
            videoButton.isHidden = true
        } else {
            phoneButton.isHidden = false
            videoButton.isHidden = false
        }
    }

    @IBAction func startVideoClick(_ sender: UIButton) {
        delegate?.startCall(.video, userInfo: cellModel ?? UserInfo())
    }
    
    @IBAction func startPhoneClick(_ sender: UIButton) {
        delegate?.startCall(.voice, userInfo: cellModel ?? UserInfo())
    }

}
