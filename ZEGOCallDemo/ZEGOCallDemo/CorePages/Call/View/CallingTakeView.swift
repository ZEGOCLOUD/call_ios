//
//  CallingTakeView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

class CallingTakeView: CallBaseView {

    
    @IBAction func hangUpButtonClick(_ sender: UIButton) {
        delegate?.callhandUp(self)
    }
    
}
