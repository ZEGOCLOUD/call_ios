//
//  OnlineUserListVC+Call.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import Foundation

extension OnlineUserListVC: OnlineUserListCellDelegate {
    func startCall(_ type: CallActionType) {
        switch type {
        case .phone:
            let vc: CallMainVC = CallMainVC(nibName :"CallMainVC",bundle : nil)
            vc.modalPresentationStyle = .fullScreen;
            vc.setCallType(.phone, status: .take)
            self.present(vc, animated: true, completion: nil)
        case .video:
            let vc: CallMainVC = CallMainVC(nibName :"CallMainVC",bundle : nil)
            vc.modalPresentationStyle = .fullScreen;
            vc.setCallType(.video, status: .take)
            self.present(vc, animated: true, completion: nil)
            break
        }
    }
}
