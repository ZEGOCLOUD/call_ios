//
//  SettingSecondLevelCell.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/6.
//

import UIKit


class SettingSecondLevelCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedButton: UIButton!
    
    var cellModel: CallSettingSecondLevelModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
    }
    
    @IBAction func selectedClick(_ sender: UIButton) {
        
    }
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        backgroundColor = highlighted ? ZegoColor("D8D8D8_10") : UIColor.clear
    }
    func updateCell(_ model: CallSettingSecondLevelModel) -> Void {
        cellModel = model
        titleLabel.text = model.title
        titleLabel.textColor = model.isSelected ? UIColor.black : ZegoColor("A4A4A4")
        selectedButton.isHidden = !model.isSelected
    }
    
}
