//
//  OnlineUserListCell.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/11.
//

import UIKit

class OnlineUserListCell: UITableViewCell {
    
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func startVideoClick(_ sender: UIButton) {
        
    }
    
    @IBAction func startPhoneClick(_ sender: UIButton) {
        
    }
    
    

}
