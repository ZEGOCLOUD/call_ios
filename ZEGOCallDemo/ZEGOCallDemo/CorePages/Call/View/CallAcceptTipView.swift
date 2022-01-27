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
    func tipViewDidClik(_ userInfo: UserInfo, callType: CallType)
}

class CallAcceptTipView: UIView {
    
    @IBOutlet weak var headImage: UIImageView! {
        didSet {
            headImage.layer.masksToBounds = true
            headImage.layer.cornerRadius = 21
        }
    }
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    
    var tipType: CallType = .audio
    var callUserInfo: UserInfo?
    weak var delegate: CallAcceptTipViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapClick: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(viewTap))
        self.addGestureRecognizer(tapClick)
    }
    
    static func showTip(_ type:CallType, userInfo: UserInfo) -> CallAcceptTipView {
        return showTipView(type, userInfo: userInfo)
    }
    
    static func showTipView(_ type: CallType, userInfo: UserInfo) -> CallAcceptTipView {
        let tipView: CallAcceptTipView = UINib(nibName: "CallAcceptTipView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallAcceptTipView
        let y = KeyWindow().safeAreaInsets.top
        tipView.frame = CGRect.init(x: 8, y: y + 8, width: UIScreen.main.bounds.size.width - 16, height: 80)
        tipView.userNameLabel.text = userInfo.userName
        tipView.layer.masksToBounds = true
        tipView.layer.cornerRadius = 8
        tipView.callUserInfo = userInfo
        tipView.headImage.image = UIImage(named: String.getHeadImageName(userName: userInfo.userName))
        tipView.tipType = type
        switch type {
        case .audio:
            tipView.messageLabel.text = ZGLocalizedString("zego_video_call")
            tipView.acceptButton.setImage(UIImage(named: "call_accept_icon"), for: .normal)
        case .video:
            tipView.messageLabel.text = ZGLocalizedString("zego_voice_call")
            tipView.acceptButton.setImage(UIImage(named: "call_video_icon"), for: .normal)
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
    
    @objc func viewTap() {
        if let callUserInfo = callUserInfo {
            delegate?.tipViewDidClik(callUserInfo, callType: tipType)
        }
        CallAcceptTipView.dismiss()
    }
    
}
