//
//  DefaultRefreshView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/14.
//

import UIKit

class DefaultRefreshView: UIView {
    
    fileprivate(set) lazy var activityIndicator: UIActivityIndicatorView! = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        self.addSubview(activityIndicator)
        return activityIndicator
    }()

    override func layoutSubviews() {
        centerActivityIndicator()
        setupFrame(in: superview)
        
        super.layoutSubviews()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        centerActivityIndicator()
        setupFrame(in: superview)
    }
}

private extension DefaultRefreshView {
    
    func setupFrame(in newSuperview: UIView?) {
        guard let superview = newSuperview else { return }

        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: superview.frame.width, height: frame.height)
    }
    
     func centerActivityIndicator() {
        activityIndicator.center = convert(center, from: superview)
    }
}