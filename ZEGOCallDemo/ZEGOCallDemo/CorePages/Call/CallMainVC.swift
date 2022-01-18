//
//  CallMainVC.swift
//  ZEGOCallDemo
//
//  Created by zego on 2022/1/13.
//

import UIKit

enum CallVCType {
    case phone
    case video
}

enum CallStatusType {
    case take
    case accept
    case calling
}

class CallMainVC: UIViewController {
    
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var backGroundImage: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var headImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var callQualityLabel: UILabel!
    
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet weak var toBottomDistance: NSLayoutConstraint!
    
    var bgImage: UIImage?

    lazy var takeView: CallingTakeView = {
        let view: CallingTakeView = UINib(nibName: "CallingTakeView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallingTakeView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 60)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    lazy var acceptView: CallAcceptView = {
        let view: CallAcceptView = UINib(nibName: "CallAcceptView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallAcceptView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 85)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    lazy var phoneView: CallingPhoneView = {
        let view: CallingPhoneView = UINib(nibName: "CallingPhoneView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallingPhoneView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 60)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    lazy var videoView: CallingVideoView = {
        let view: CallingVideoView = UINib(nibName: "CallingVideoView", bundle: nil).instantiate(withOwner: nil, options: nil).first as! CallingVideoView
        view.delegate = self
        view.frame = CGRect.init(x: 0, y: 0, width: self.view.bounds.size.width, height: 60)
        view.isHidden = true
        bottomView.addSubview(view)
        return view
    }()
    
    var callUser: UserInfo?
    var vcType: CallVCType = .phone
    var statusType: CallStatusType = .take
    var useFrontCamera: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configUI()
    }
    
    static func loadCallMainVC(_ type: CallVCType, userInfo: UserInfo, status: CallStatusType) -> CallMainVC {
        let vc: CallMainVC = CallMainVC(nibName :"CallMainVC",bundle : nil)
        vc.modalPresentationStyle = .fullScreen;
        vc.callUser = userInfo
        vc.vcType = type
        vc.statusType = status
        switch type {
        case .phone:
            vc.bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
        case .video:
            vc.bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
            
        }
        return vc
    }
    
    func configUI() {
        backGroundImage.image = bgImage
        headImage.image = UIImage(named: String.getHeadImageName(userName: callUser?.userName))
        userNameLabel.text = callUser?.userName
        if vcType == .phone {
            backGroundImage.isHidden = true
        } else {
            backGroundImage.isHidden = false
        }
        self.callStatusLabel.isHidden = true
        self.bottomViewHeight.constant = 60
        self.toBottomDistance.constant = 52.5
        switch statusType {
        case .take:
            self.callStatusLabel.text = "Calling..."
            self.callStatusLabel.isHidden = false
            self.takeView.isHidden = false
            self.acceptView.isHidden = true
            self.phoneView.isHidden = true
            self.videoView.isHidden = true
        case .accept:
            self.bottomViewHeight.constant = 85
            self.toBottomDistance.constant = 28
            self.callStatusLabel.text = "Calling..."
            self.callStatusLabel.isHidden = false
            self.takeView.isHidden = true
            self.acceptView.isHidden = false
            self.phoneView.isHidden = true
            self.videoView.isHidden = true
        case .calling:
            self.takeView.isHidden = true
            self.acceptView.isHidden = true
            if vcType == .phone {
                self.phoneView.isHidden = false
                self.videoView.isHidden = true
            } else {
                self.phoneView.isHidden = true
                self.videoView.isHidden = false
            }
        }
    }
    
    func updateCallType(_ type: CallVCType, userInfo: UserInfo, status: CallStatusType) {
        callUser = userInfo
        vcType = type
        statusType = status
        
        switch type {
        case .phone:
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
        case .video:
            bgImage = UIImage.getBlurImage(UIImage(named: String.getCallCoverImageName(userName: userInfo.userName)))
            
        }
        configUI()
    }
}
