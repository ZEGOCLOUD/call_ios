//
//  CallBaseView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import UIKit

protocol CallActionDelegate: AnyObject {
    func callhandUp()
    func callAccept()
    func callDecline()
    func callOpenMic(_ isOpen: Bool)
    func callOpenVoice(_ isOpen: Bool)
    func callOpenVideo(_ isOpen: Bool)
    func callFlipCamera()
}

class CallBaseView: UIView {
    
    weak var delegate: CallActionDelegate?

}
