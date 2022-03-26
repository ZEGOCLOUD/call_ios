//
//  DefaultViewAnimator.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/14.
//

import Foundation

class DefaultViewAnimator: RefreshViewAnimator {

    fileprivate let refreshView: DefaultRefreshView
    
    init(refreshView: DefaultRefreshView) {
        self.refreshView = refreshView
    }
    
    func animate(_ state: State) {
        switch state {
        case .initial:
            refreshView.activityIndicator.stopAnimating()
            
        case .releasing(let progress):
            refreshView.activityIndicator.isHidden = false
            
            var transform = CGAffineTransform.identity
            transform = transform.scaledBy(x: progress, y: progress)
            transform = transform.rotated(by: CGFloat(M_PI) * progress * 2)
            refreshView.activityIndicator.transform = transform
            
        case .loading:
            refreshView.activityIndicator.startAnimating()
            
        default: break
        }
    }
    
}
