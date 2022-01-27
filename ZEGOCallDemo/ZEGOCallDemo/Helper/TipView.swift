//
//  TipView.swift
//  ZEGOLiveDemo
//
//  Created by zego on 2022/1/7.
//

import UIKit

enum TipViewType: Int {
    case warn
    case tip
}

class TipView: UIView {

    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var viewType: TipViewType = .warn
    var autoDismiss: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func showTip(_ message: String, autoDismiss: Bool = true) {
        showTipView(.tip, message: message, autoDismiss: autoDismiss)
    }
    
    static func showWarn(_ message: String, autoDismiss: Bool = true) {
        showTipView(.warn, message: message, autoDismiss: autoDismiss)
    }
    
    static func showTipView(_ type: TipViewType, message: String, autoDismiss: Bool = true) {
        DispatchQueue.main.async {
            let tipView: TipView = UINib(nibName: "TipView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! TipView
            let y = KeyWindow().safeAreaInsets.top
            tipView.frame = CGRect.init(x: 0, y: y, width: UIScreen.main.bounds.size.width, height: 70)
            tipView.autoDismiss = autoDismiss
            switch type {
            case .warn:
                tipView.backGroundView.backgroundColor = ZegoColor("FF4A50")
            case .tip:
                tipView.backGroundView.backgroundColor = ZegoColor("55BC9E")
            }
            tipView.messageLabel.text = message
            tipView.show()
        }
    }
        
    static func dismiss() {
        DispatchQueue.main.async {
            for subview in KeyWindow().subviews {
                if subview is TipView {
                    let view: TipView = subview as! TipView
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    private func show()  {
        KeyWindow().addSubview(self)
        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                TipView.dismiss()
            }
        }
    }

}
