//
//  MinimizeCallView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/3/16.
//

import UIKit

protocol MinimizeCallViewDelegate: AnyObject {
    func didClickMinimizeCallView() ;
}

class MinimizeCallView: UIView {
    
    @IBOutlet weak var backGroundView: UIView! {
        didSet {
            let maskPath = UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: backGroundView.bounds.size.width, height: backGroundView.bounds.size.height), byRoundingCorners: [.topLeft,.bottomLeft], cornerRadii: CGSize.init(width: 39, height: 39))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = backGroundView.bounds
            maskLayer.path = maskPath.cgPath
            backGroundView.layer.mask = maskLayer
        }
    }
    
    @IBOutlet weak var blueCircleView: UIView! {
        didSet {
            let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
            blueCircleView.addGestureRecognizer(tapClick)
        }
    }
    
    @IBOutlet weak var statusImageView: UIImageView! {
        didSet {
            updateCallStatus(currentStatus)
        }
    }
    
    
    @IBOutlet weak var waitLabel: UILabel! {
        didSet {
            updateCallStatus(currentStatus)
        }
    }
    
    @objc func tapClick() {
        delegate?.didClickMinimizeCallView()
    }
    
    weak var delegate: MinimizeCallViewDelegate?
    var currentStatus: MinimizedCallStatus = .waiting
    
    static func initMinimizeCall(_ status: MinimizedCallStatus) -> MinimizeCallView {
        let view: MinimizeCallView = UINib(nibName: "MinimizeCallView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! MinimizeCallView
        view.frame = CGRect.init(x: UIScreen.main.bounds.size.width - 78, y: UIScreen.main.bounds.size.height - 78 - 60, width: 78, height: 78)
        view.updateCallStatus(status)
        return view
    }
    
    func updateCallStatus(_ status: MinimizedCallStatus) {
        switch status {
        case .waiting:
            waitLabel.text = "wait..."
        case .decline:
            waitLabel.text = "Declined"
        case .calling:
            waitLabel.text = ""
        case .miss:
            waitLabel.text = "Missed"
        case .end:
            waitLabel.text = "Ended"
        }
    }

}
