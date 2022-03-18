//
//  CallMainVC+Setting.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/17.
//

import Foundation

extension CallMainVC: CallSettingViewDelegate, CallSettingSecondViewDelegate  {
    
    func settingViewDidSelected(_ model: CallSettingModel, type: CallSettingViewType) {
        switch model.selectionType {
        case .videoResolution:
            if type == .video {
                callSettingView?.isHidden = true
                resolutionView?.isHidden = false
            } else {
                callAudioSettingView?.isHidden = true
                resolutionView?.isHidden = false
            }
        case .bitrate:
            if type == .video {
                callSettingView?.isHidden = true
                bitrateView?.isHidden = false
            } else {
                callAudioSettingView?.isHidden = true
                bitrateView?.isHidden = false
            }
        case .noiseSuppression, .echoCancellation, .volumeAdjustment:
            return
        }
    }
        
    func settingSecondViewDidBack() {
        if vcType == .video {
            callSettingView?.isHidden = false
            callSettingView?.updateUI()
        } else {
            callAudioSettingView?.isHidden = false
            callAudioSettingView?.updateUI()
        }
    }
    

}
