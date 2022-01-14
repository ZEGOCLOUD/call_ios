//
//  CallMainVC+Operation.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/14.
//

import Foundation

extension CallMainVC: CallActionDelegate {
    func callhandUp(_ callView: CallBaseView) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func callAccept(_ callView: CallBaseView) {
        
    }
    
    func callDecline(_ callView: CallBaseView) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func callOpenMic(_ callView: CallBaseView, isOpen: Bool) {
        
    }
    
    func callOpenVoice(_ callView: CallBaseView, isOpen: Bool) {
        
    }
    
    func callOpenVideo(_ callView: CallBaseView, isOpen: Bool) {
        
    }
    
    func callFlipCamera(_ callView: CallBaseView) {
        
    }
}
