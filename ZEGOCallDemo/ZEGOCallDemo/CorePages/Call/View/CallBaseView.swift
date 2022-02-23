//
//  CallBaseView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import UIKit

protocol CallActionDelegate: AnyObject {
    func callhandUp(_ callView: CallBaseView)
    func callAccept(_ callView: CallBaseView)
    func callDecline(_ callView: CallBaseView)
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool)
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool)
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool)
    func callFlipCamera(_ callView: CallBaseView)
}

class CallBaseView: UIView {
    
    weak var delegate: CallActionDelegate?
    

}
