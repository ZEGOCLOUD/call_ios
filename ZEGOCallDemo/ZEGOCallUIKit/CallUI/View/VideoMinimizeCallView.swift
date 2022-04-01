//
//  VideoMinimizeCallView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/16.
//

import UIKit

protocol VideoMinimizeCallViewDelegate: AnyObject {
    func didClickVideoMinimizeCallView()
}

class VideoMinimizeCallView: UIView {
    
    weak var delegate: VideoMinimizeCallViewDelegate?
    
    @IBOutlet weak var backGroundView: UIView! {
        didSet {
            let maskPath = UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: backGroundView.bounds.size.width, height: backGroundView.bounds.size.height), byRoundingCorners: [.topLeft,.bottomLeft], cornerRadii: CGSize.init(width: 10, height: 10))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = backGroundView.bounds
            maskLayer.path = maskPath.cgPath
            backGroundView.layer.mask = maskLayer
        }
    }
    
    
    @IBOutlet weak var localVideoPreview: UIView! {
        didSet {
            let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
            localVideoPreview.addGestureRecognizer(tapClick)
        }
    }
    
    @objc func tapClick() {
        delegate?.didClickVideoMinimizeCallView()
    }
    
    static func initVideoMinimizeCall(_ status: MinimizedCallStatus) -> VideoMinimizeCallView {
        let view: VideoMinimizeCallView = UINib(nibName: "VideoMinimizeCallView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! VideoMinimizeCallView
        view.frame = CGRect.init(x: UIScreen.main.bounds.size.width - 78, y: UIScreen.main.bounds.size.height - 130 - 60, width: 78, height: 130)
        return view
    }
}
