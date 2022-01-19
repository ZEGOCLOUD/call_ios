//
//  CallAcceptTipView.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/12.
//

import UIKit

protocol CallAcceptTipViewDelegate: AnyObject {
    func tipViewDeclineCall(_ userInfo: UserInfo, callType: CallType)
    func tipViewAcceptCall(_ userInfo: UserInfo, callType: CallType)
}

class CallAcceptTipView: UIView {
    
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    var tipType: CallType = .audio
    var callUserInfo: UserInfo?
    weak var delegate: CallAcceptTipViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func showTip(_ type:CallType, userInfo: UserInfo) -> CallAcceptTipView {
        return showTipView(type, userInfo: userInfo)
    }
    
    static func showTipView(_ type: CallType, userInfo: UserInfo) -> CallAcceptTipView {
        let tipView: CallAcceptTipView = UINib(nibName: "CallAcceptTipView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallAcceptTipView
        let y = KeyWindow().safeAreaInsets.top
        tipView.frame = CGRect.init(x: 8, y: y, width: UIScreen.main.bounds.size.width - 16, height: 80)
        tipView.userNameLabel.text = userInfo.userName
        tipView.layer.masksToBounds = true
        tipView.layer.cornerRadius = 8
        tipView.callUserInfo = userInfo
        tipView.headImage.image = UIImage(named: String.getHeadImageName(userName: userInfo.userName))
        switch type {
        case .audio:
            tipView.messageLabel.text = "ZEGO Voice Call"
        case .video:
            tipView.messageLabel.text = "ZEGO Video Call"
        }
        tipView.show()
        return tipView
    }
        
    static func dismiss() {
        DispatchQueue.main.async {
            for subview in KeyWindow().subviews {
                if subview is CallAcceptTipView {
                    let view: CallAcceptTipView = subview as! CallAcceptTipView
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func show()  {
        KeyWindow().addSubview(self)
    }
    
    
    @IBAction func declineButtonClick(_ sender: UIButton) {
        if let callUserInfo = callUserInfo {
            delegate?.tipViewDeclineCall(callUserInfo, callType: tipType)
        }
        CallAcceptTipView.dismiss()
    }
    
    @IBAction func acceptButtonClick(_ sender: UIButton) {
        if let callUserInfo = callUserInfo {
            delegate?.tipViewAcceptCall(callUserInfo, callType: tipType)
        }
        CallAcceptTipView.dismiss()
    }
    
}
