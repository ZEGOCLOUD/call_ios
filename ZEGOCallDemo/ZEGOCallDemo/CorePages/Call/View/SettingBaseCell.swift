//
//  SettingBaseCell.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/5.
//

import UIKit

class SettingBaseCell: UITableViewCell {
    
    var cellModel: CallSettingModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateCell(_ model: CallSettingModel) -> Void {
        
    }

}
