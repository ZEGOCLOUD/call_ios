//
//  SettingParamDisplayCell.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/5.
//

import UIKit

class SettingParamDisplayCell: SettingBaseCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func updateCell(_ model: CallSettingModel) {
        super.updateCell(model)
        cellModel = model
        titleLabel.text = model.title
        descLabel.text = model.subTitle
    }
    
}
